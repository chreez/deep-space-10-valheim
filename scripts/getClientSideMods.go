/*
getClientSideMods - Fetch Valheim mod information from Thunderstore API or r2modman profile

AI USAGE GUIDE:
- Default: Returns all fields except source URLs (~3.4MB)
- Use --minimal for names/versions only (~794KB, 77% reduction)
- Use --profile to read from Windows r2modman profile (instant, only installed mods)
- Use --with-source to discover GitHub URLs (slower, API rate limited)
- Use --silent for clean JSON output (no progress messages)
- Use --filter-mod for specific mod lookup

EXAMPLES:
  # Read from Windows r2modman profile (best for installed mods):
  getClientSideMods --profile DS10 --silent --format json
  
  # Minimal output from Thunderstore (best for AI - 77% smaller):
  getClientSideMods --minimal --silent --format json
  
  # Single mod with source URL:
  getClientSideMods --filter-mod "ValheimModding-Jotunn" --with-source --silent --format json
  
  # Profile mods with source discovery:
  getClientSideMods --profile DS10 --with-source --silent --format json

OPTIMIZATION:
- With --profile: Instant, only installed mods (~20-100 mods)
- With --minimal: ~794KB (names + versions only)
- Without --with-source: ~3.4MB (all fields)
- With --with-source: +300ms/mod throttle
- Filter to specific mods when possible

NEW IN v3:
- --profile flag to read from Windows r2modman profiles
- Reads mods.yml via SSH from Windows server
- Shows only enabled mods from profile
*/

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"sort"
	"strings"
	"time"
)

// ============================================================================
// DATA STRUCTURES
// ============================================================================

type Mod struct {
	Name        string `json:"name"`
	FullName    string `json:"full_name"`
	Owner       string `json:"owner"`
	Description string `json:"description"`
	WebsiteURL  string `json:"website_url"`
	SourceURL   string `json:"source_url"`
	Downloads   int    `json:"downloads"`
	Rating      int    `json:"rating"`
	Categories  []string `json:"categories"`
	Version     string `json:"latest_version"`
	LastUpdate  string `json:"last_updated"`
}

// MinimalMod contains only essential fields for token optimization
type MinimalMod struct {
	FullName string `json:"full_name"`
	Version  string `json:"latest_version"`
}

type ThunderstoreMod struct {
	Name         string `json:"name"`
	FullName     string `json:"full_name"`
	Owner        string `json:"owner"`
	PackageURL   string `json:"package_url"`
	DonationLink string `json:"donation_link"`
	WebsiteURL   string `json:"website_url"`
	Description  string `json:"description"`
	IsDeprecated bool   `json:"is_deprecated"`
	Categories   []string `json:"categories"`
	RatingScore  int    `json:"rating_score"`
	Downloads    int    `json:"downloads"`
	Versions     []struct {
		Name        string `json:"name"`
		FullName    string `json:"full_name"`
		Description string `json:"description"`
		VersionNumber string `json:"version_number"`
		Downloads     int    `json:"downloads"`
		DateCreated   string `json:"date_created"`
		WebsiteURL    string `json:"website_url"`
		IsActive      bool   `json:"is_active"`
	} `json:"versions"`
}

type ThunderstoreResponse []ThunderstoreMod

type GitHubRepo struct {
	FullName    string `json:"full_name"`
	HTMLURL     string `json:"html_url"`
	Description string `json:"description"`
	Stars       int    `json:"stargazers_count"`
}

type GitHubSearchResponse struct {
	Items []GitHubRepo `json:"items"`
}

// R2ModMan profile mod structure
type ProfileMod struct {
	Name         string `yaml:"name"`
	AuthorName   string `yaml:"authorName"`
	DisplayName  string `yaml:"displayName"`
	Description  string `yaml:"description"`
	WebsiteURL   string `yaml:"websiteUrl"`
	VersionNumber struct {
		Major int `yaml:"major"`
		Minor int `yaml:"minor"`
		Patch int `yaml:"patch"`
	} `yaml:"versionNumber"`
	Enabled bool `yaml:"enabled"`
}

type Logger struct {
	level string
	quiet bool
	silent bool
}

func NewLogger(level string, quiet bool, silent bool) *Logger {
	return &Logger{level: level, quiet: quiet, silent: silent}
}

func (l *Logger) Debug(format string, args ...interface{}) {
	if !l.quiet && !l.silent && (l.level == "debug" || l.level == "trace") {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		fmt.Fprintf(os.Stderr, "[%s] [DEBUG] %s\n", timestamp, fmt.Sprintf(format, args...))
	}
}

func (l *Logger) Info(format string, args ...interface{}) {
	if !l.quiet && !l.silent && (l.level == "debug" || l.level == "info") {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		fmt.Fprintf(os.Stderr, "[%s] [INFO] %s\n", timestamp, fmt.Sprintf(format, args...))
	}
}

func (l *Logger) Error(format string, args ...interface{}) {
	if !l.quiet && !l.silent {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		fmt.Fprintf(os.Stderr, "[%s] [ERROR] %s\n", timestamp, fmt.Sprintf(format, args...))
	}
}

func (l *Logger) Progress(format string, args ...interface{}) {
	if !l.silent {
		fmt.Fprintf(os.Stderr, "%s\n", fmt.Sprintf(format, args...))
	}
}

// ============================================================================
// SOURCE URL DISCOVERY
// ============================================================================

type SourceDiscovery struct {
	logger     *Logger
	httpClient *http.Client
	cache      map[string]string
	throttleDelay time.Duration
}

func NewSourceDiscovery(logger *Logger) *SourceDiscovery {
	return &SourceDiscovery{
		logger: logger,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
		cache: make(map[string]string),
		throttleDelay: 300 * time.Millisecond,
	}
}

// Method 1: Check if website_url contains GitHub URL directly
func (s *SourceDiscovery) method1DirectAPI(mod ThunderstoreMod) (string, bool) {
	s.logger.Info("Method 1: Checking Thunderstore API for GitHub URL")
	
	githubRegex := regexp.MustCompile(`https?://github\.com/[^/\s]+/[^/\s]+`)
	
	if match := githubRegex.FindString(mod.WebsiteURL); match != "" {
		s.logger.Info("Method 1: Found GitHub URL in Thunderstore API")
		return strings.TrimSuffix(match, "/"), true
	}
	
	s.logger.Info("Method 1: No GitHub URL in Thunderstore API (found: %s)", mod.WebsiteURL)
	return "", false
}

// Method 2: Extract GitHub URL from README/description
func (s *SourceDiscovery) method2ReadmeExtraction(mod ThunderstoreMod) (string, bool) {
	s.logger.Info("Method 2: Extracting from README content")
	
	githubRegex := regexp.MustCompile(`https?://github\.com/[^/\s\)]+/[^/\s\)]+`)
	
	// Check description first
	if match := githubRegex.FindString(mod.Description); match != "" {
		s.logger.Info("Method 2: Found GitHub URL in README")
		return strings.TrimSuffix(match, "/"), true
	}
	
	// Check version descriptions
	for _, version := range mod.Versions {
		if match := githubRegex.FindString(version.Description); match != "" {
			s.logger.Info("Method 2: Found GitHub URL in version description")
			return strings.TrimSuffix(match, "/"), true
		}
	}
	
	s.logger.Info("Method 2: No GitHub URL found in README")
	return "", false
}

// Method 3: Search GitHub API
func (s *SourceDiscovery) method3GitHubSearch(mod ThunderstoreMod) (string, bool) {
	s.logger.Info("Method 3: Searching GitHub API for \"%s valheim\"", mod.Name)
	
	// Throttle API calls
	time.Sleep(s.throttleDelay)
	
	// Build search query
	query := fmt.Sprintf("%s valheim", mod.Name)
	searchURL := fmt.Sprintf("https://api.github.com/search/repositories?q=%s&sort=stars&order=desc&per_page=5", 
		url.QueryEscape(query))
	
	resp, err := s.httpClient.Get(searchURL)
	if err != nil {
		s.logger.Error("Method 3: GitHub API request failed: %v", err)
		return "", false
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 403 {
		s.logger.Error("Method 3: GitHub API rate limited")
		return "", false
	}
	
	if resp.StatusCode != 200 {
		s.logger.Error("Method 3: GitHub API returned status %d", resp.StatusCode)
		return "", false
	}
	
	var searchResp GitHubSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResp); err != nil {
		s.logger.Error("Method 3: Failed to parse GitHub API response: %v", err)
		return "", false
	}
	
	// Look for matching repositories
	for _, repo := range searchResp.Items {
		// Check if repo name or description contains the mod name
		repoNameLower := strings.ToLower(repo.FullName)
		descLower := strings.ToLower(repo.Description)
		modNameLower := strings.ToLower(mod.Name)
		
		if strings.Contains(repoNameLower, modNameLower) || 
		   strings.Contains(descLower, modNameLower) {
			s.logger.Info("Method 3: Found potential match")
			return repo.HTMLURL, true
		}
	}
	
	s.logger.Info("Method 3: No results from GitHub search")
	return "", false
}

// Method 4: Check author's other mods for pattern
func (s *SourceDiscovery) method4AuthorPattern(mod ThunderstoreMod) (string, bool) {
	s.logger.Info("Method 4: Checking author's GitHub profile pattern")
	
	// Try common GitHub username patterns
	possibleUsernames := []string{
		mod.Owner,
		strings.ReplaceAll(mod.Owner, "-", ""),
		strings.ReplaceAll(mod.Owner, "_", ""),
	}
	
	for _, username := range possibleUsernames {
		// Try different repository name patterns
		repoNames := []string{
			mod.Name,
			"ValheimMods",
			"Valheim-Mods", 
			fmt.Sprintf("Valheim-%s", mod.Name),
			fmt.Sprintf("%s-Valheim", mod.Name),
		}
		
		for _, repoName := range repoNames {
			// Throttle API calls
			time.Sleep(s.throttleDelay)
			
			testURL := fmt.Sprintf("https://github.com/%s/%s", username, repoName)
			
			// Quick HEAD request to check if repo exists
			req, _ := http.NewRequest("HEAD", testURL, nil)
			resp, err := s.httpClient.Do(req)
			if err == nil {
				resp.Body.Close()
				if resp.StatusCode == 200 {
					s.logger.Info("Method 4: Found GitHub URL via pattern matching")
					return testURL, true
				}
			}
		}
	}
	
	s.logger.Info("Method 4: No GitHub URL found for author's other mods")
	return "", false
}

// Discover source URL using all methods
func (s *SourceDiscovery) DiscoverSourceURL(mod ThunderstoreMod) string {
	s.logger.Info("Discovering source URL for %s", mod.FullName)
	
	// Show progress
	s.logger.Progress("Working on mod: [%s]", mod.FullName)
	s.logger.Progress("Status: Getting GitHub URL (throttled)")
	
	// Check cache first
	if cached, exists := s.cache[mod.FullName]; exists {
		s.logger.Progress("Result of mod source repo: %s\n", cached)
		return cached
	}
	
	// Try each method in order
	methods := []func(ThunderstoreMod) (string, bool){
		s.method1DirectAPI,
		s.method2ReadmeExtraction,
		s.method3GitHubSearch,
		s.method4AuthorPattern,
	}
	
	for _, method := range methods {
		if url, found := method(mod); found {
			s.cache[mod.FullName] = url
			s.logger.Info("Source URL: %s", url)
			s.logger.Progress("Result of mod source repo: %s\n", url)
			return url
		}
	}
	
	s.logger.Info("Source URL: null")
	s.logger.Progress("Result of mod source repo: null\n")
	s.cache[mod.FullName] = ""
	return ""
}

// ============================================================================
// MAIN FUNCTIONALITY
// ============================================================================

type Config struct {
	FilterMod    string
	Format       string
	LogLevel     string
	Quiet        bool
	Silent       bool
	RefreshCache bool
	WithSource   bool
	Minimal      bool
	Profile      string
}

func fetchThunderstoreMods(logger *Logger) ([]ThunderstoreMod, error) {
	logger.Info("Fetching mods from Thunderstore API")
	
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get("https://thunderstore.io/c/valheim/api/v1/package/")
	if err != nil {
		return nil, fmt.Errorf("failed to fetch from Thunderstore API: %v", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Thunderstore API returned status %d", resp.StatusCode)
	}
	
	var mods []ThunderstoreMod
	if err := json.NewDecoder(resp.Body).Decode(&mods); err != nil {
		return nil, fmt.Errorf("failed to parse Thunderstore response: %v", err)
	}
	
	logger.Info("Successfully fetched %d mods from Thunderstore", len(mods))
	return mods, nil
}

func fetchProfileMods(profile string, logger *Logger) ([]ThunderstoreMod, error) {
	logger.Info("Fetching mods from Windows r2modman profile: %s", profile)
	
	// Build the path to mods.yml
	profilePath := fmt.Sprintf("/mnt/c/Users/Chris/AppData/Roaming/r2modmanPlus-local/Valheim/profiles/%s/mods.yml", profile)
	
	// Use SSH tool to read the file
	sshCmd := os.ExpandEnv("$HOME/.dotfiles/bin/ssh_windows_wsl")
	cmd := exec.Command(sshCmd, "--command", fmt.Sprintf("cat '%s'", profilePath))
	
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to read profile from Windows: %v", err)
	}
	
	// Parse YAML manually since we don't have the yaml package
	// For now, use a simple parser for the specific format
	var profileMods []ProfileMod
	
	// Simple parsing of the YAML-like format
	lines := strings.Split(string(output), "\n")
	var currentMod *ProfileMod
	
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		
		// New mod entry
		if strings.HasPrefix(line, "- manifestVersion:") {
			if currentMod != nil && currentMod.Enabled {
				profileMods = append(profileMods, *currentMod)
			}
			currentMod = &ProfileMod{Enabled: true}
			continue
		}
		
		if currentMod == nil {
			continue
		}
		
		// Parse fields
		if strings.HasPrefix(trimmed, "name:") {
			currentMod.Name = strings.TrimSpace(strings.TrimPrefix(trimmed, "name:"))
		} else if strings.HasPrefix(trimmed, "authorName:") {
			currentMod.AuthorName = strings.TrimSpace(strings.TrimPrefix(trimmed, "authorName:"))
		} else if strings.HasPrefix(trimmed, "displayName:") {
			currentMod.DisplayName = strings.TrimSpace(strings.TrimPrefix(trimmed, "displayName:"))
		} else if strings.HasPrefix(trimmed, "description:") {
			currentMod.Description = strings.TrimSpace(strings.TrimPrefix(trimmed, "description:"))
		} else if strings.HasPrefix(trimmed, "websiteUrl:") {
			currentMod.WebsiteURL = strings.TrimSpace(strings.TrimPrefix(trimmed, "websiteUrl:"))
		} else if strings.HasPrefix(trimmed, "enabled:") {
			currentMod.Enabled = strings.TrimSpace(strings.TrimPrefix(trimmed, "enabled:")) == "true"
		} else if strings.HasPrefix(trimmed, "major:") {
			fmt.Sscanf(trimmed, "major: %d", &currentMod.VersionNumber.Major)
		} else if strings.HasPrefix(trimmed, "minor:") {
			fmt.Sscanf(trimmed, "minor: %d", &currentMod.VersionNumber.Minor)
		} else if strings.HasPrefix(trimmed, "patch:") {
			fmt.Sscanf(trimmed, "patch: %d", &currentMod.VersionNumber.Patch)
		}
	}
	
	// Add the last mod
	if currentMod != nil && currentMod.Enabled {
		profileMods = append(profileMods, *currentMod)
	}
	
	// Convert to ThunderstoreMod format
	var tsMods []ThunderstoreMod
	for _, pm := range profileMods {
		if !pm.Enabled {
			continue
		}
		
		// The name already includes author prefix, so use it directly
		fullName := pm.Name
		version := fmt.Sprintf("%d.%d.%d", 
			pm.VersionNumber.Major, 
			pm.VersionNumber.Minor, 
			pm.VersionNumber.Patch)
		
		tsMod := ThunderstoreMod{
			Name:        pm.Name,
			FullName:    fullName,
			Owner:       pm.AuthorName,
			Description: pm.Description,
			WebsiteURL:  pm.WebsiteURL,
			RatingScore: 0,
			Downloads:   0,
			Categories:  []string{},
			Versions: []struct {
				Name          string   `json:"name"`
				FullName      string   `json:"full_name"`
				Description   string   `json:"description"`
				VersionNumber string   `json:"version_number"`
				Downloads     int      `json:"downloads"`
				DateCreated   string   `json:"date_created"`
				WebsiteURL    string   `json:"website_url"`
				IsActive      bool     `json:"is_active"`
			}{
				{
					VersionNumber: version,
					DateCreated:   time.Now().Format(time.RFC3339),
				},
			},
		}
		
		tsMods = append(tsMods, tsMod)
	}
	
	logger.Info("Successfully loaded %d enabled mods from profile", len(tsMods))
	return tsMods, nil
}

func convertToOutputFormat(tsMods []ThunderstoreMod, discovery *SourceDiscovery, filterMod string, withSource bool) []Mod {
	var mods []Mod
	
	for _, tsMod := range tsMods {
		// Apply filter early to avoid processing unwanted mods
		if filterMod != "" && tsMod.FullName != filterMod {
			continue
		}
		
		mod := Mod{
			Name:        tsMod.Name,
			FullName:    tsMod.FullName,
			Owner:       tsMod.Owner,
			Description: tsMod.Description,
			WebsiteURL:  tsMod.WebsiteURL,
			Downloads:   tsMod.Downloads,
			Rating:      tsMod.RatingScore,
			Categories:  tsMod.Categories,
		}
		
		// Only discover source URL if requested
		if withSource {
			mod.SourceURL = discovery.DiscoverSourceURL(tsMod)
		}
		
		// Get latest version info
		if len(tsMod.Versions) > 0 {
			latest := tsMod.Versions[0]
			mod.Version = latest.VersionNumber
			mod.LastUpdate = latest.DateCreated
		}
		
		mods = append(mods, mod)
	}
	
	// Sort mods alphabetically by full_name (case-insensitive)
	sort.Slice(mods, func(i, j int) bool {
		return strings.ToLower(mods[i].FullName) < strings.ToLower(mods[j].FullName)
	})
	
	return mods
}

func filterMods(mods []Mod, filterMod string) []Mod {
	if filterMod == "" {
		return mods
	}
	
	var filtered []Mod
	for _, mod := range mods {
		if mod.FullName == filterMod {
			filtered = append(filtered, mod)
		}
	}
	
	return filtered
}

func outputMods(mods []Mod, format string, minimal bool) {
	// Handle minimal mode
	if minimal && format == "json" {
		minimalMods := make([]MinimalMod, len(mods))
		for i, mod := range mods {
			minimalMods[i] = MinimalMod{
				FullName: mod.FullName,
				Version:  mod.Version,
			}
		}
		
		output := struct {
			Mods []MinimalMod `json:"mods"`
		}{Mods: minimalMods}
		
		data, err := json.MarshalIndent(output, "", "  ")
		if err != nil {
			log.Fatalf("Failed to marshal JSON: %v", err)
		}
		fmt.Println(string(data))
		return
	}
	
	// Regular output modes
	outputModsRegular(mods, format)
}

func outputModsRegular(mods []Mod, format string) {
	switch format {
	case "json":
		output := struct {
			Mods []Mod `json:"mods"`
		}{Mods: mods}
		
		data, err := json.MarshalIndent(output, "", "  ")
		if err != nil {
			log.Fatalf("Failed to marshal JSON: %v", err)
		}
		fmt.Println(string(data))
		
	case "table":
		// Simple table output
		fmt.Printf("%-30s %-20s %-10s %-50s\n", "NAME", "OWNER", "DOWNLOADS", "SOURCE_URL")
		fmt.Println(strings.Repeat("-", 120))
		for _, mod := range mods {
			sourceURL := mod.SourceURL
			if sourceURL == "" {
				sourceURL = "null"
			}
			fmt.Printf("%-30s %-20s %-10d %-50s\n", 
				truncate(mod.Name, 30), 
				truncate(mod.Owner, 20), 
				mod.Downloads, 
				truncate(sourceURL, 50))
		}
		
	default:
		// Default: simple list
		for _, mod := range mods {
			sourceURL := mod.SourceURL
			if sourceURL == "" {
				sourceURL = "null"
			}
			fmt.Printf("%s: %s\n", mod.FullName, sourceURL)
		}
	}
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen-3] + "..."
}

func main() {
	var config Config
	
	// Command line flags
	flag.StringVar(&config.FilterMod, "filter-mod", "", "Filter to specific mod (e.g., 'ValheimModding-Jotunn')")
	flag.StringVar(&config.Format, "format", "list", "Output format: json, table, list")
	flag.StringVar(&config.LogLevel, "log-level", "", "Log level: debug, info, error (default: progress only)")
	flag.BoolVar(&config.Quiet, "quiet", false, "Disable all logs (deprecated, use --silent)")
	flag.BoolVar(&config.Silent, "silent", false, "Silent mode - only output results, no progress or logs")
	flag.BoolVar(&config.RefreshCache, "refresh-source-urls", false, "Force refresh of source URL cache")
	flag.BoolVar(&config.WithSource, "with-source", false, "Discover GitHub source URLs (slower)")
	flag.BoolVar(&config.Minimal, "minimal", false, "Minimal output mode - only name and version (optimized for AI)")
	flag.StringVar(&config.Profile, "profile", "", "Read mods from r2modman profile on Windows (e.g., DS10)")
	
	flag.Parse()
	
	// Create logger
	// Default behavior: show progress only (no logs) unless log level specified
	if config.LogLevel == "" && !config.Silent {
		// Progress display mode by default
		config.LogLevel = "progress"
	}
	logger := NewLogger(config.LogLevel, config.Quiet, config.Silent)
	
	// Fetch mods from profile or Thunderstore
	var tsMods []ThunderstoreMod
	var err error
	
	if config.Profile != "" {
		tsMods, err = fetchProfileMods(config.Profile, logger)
	} else {
		tsMods, err = fetchThunderstoreMods(logger)
	}
	
	if err != nil {
		logger.Error("Failed to fetch mods: %v", err)
		os.Exit(1)
	}
	
	// Create source discovery
	discovery := NewSourceDiscovery(logger)
	
	// Convert to output format (with early filtering)
	mods := convertToOutputFormat(tsMods, discovery, config.FilterMod, config.WithSource)
	
	// Check if filter found any results
	if config.FilterMod != "" && len(mods) == 0 {
		logger.Error("No mod found matching filter: %s", config.FilterMod)
		os.Exit(1)
	}
	
	// Output results
	outputMods(mods, config.Format, config.Minimal)
}