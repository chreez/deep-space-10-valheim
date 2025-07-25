package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// ============================================================================
// TERMINAL CAPABILITIES & ANIMATIONS
// ============================================================================

type TerminalCapabilities struct {
	unicodeSupport bool
	width          int
	colorSupport   bool
	
	// Animation frames
	spinner    []string
	pulse      []string
	progress   []string
	check      string
	cross      string
	pending    string
	active     string
	warning    string
	transition []string
	
	// Colors
	green  string
	yellow string
	red    string
	blue   string
	bold   string
	dim    string
	reset  string
}

func NewTerminalCapabilities() *TerminalCapabilities {
	t := &TerminalCapabilities{}
	
	// Detect Unicode support
	lang := os.Getenv("LANG")
	t.unicodeSupport = strings.Contains(lang, "UTF-8") || strings.Contains(lang, "utf8")
	
	// Get terminal width
	t.width = 80
	if cmd := exec.Command("tput", "cols"); cmd != nil {
		if output, err := cmd.Output(); err == nil {
			if w, err := strconv.Atoi(strings.TrimSpace(string(output))); err == nil {
				t.width = w
			}
		}
	}
	
	// Check color support
	t.colorSupport = os.Getenv("TERM") != "dumb" && isTerminal()
	
	// Set up animations
	if t.unicodeSupport {
		t.spinner = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
		t.pulse = []string{"◯", "◉"}
		t.progress = []string{"░", "▒", "▓", "█"}
		t.check = "✓"
		t.cross = "✗"
		t.pending = "○"
		t.active = "▣"
		t.warning = "⚠"
		t.transition = []string{"○", "◐", "◑", "◒", "◓", "●"}
	} else {
		t.spinner = []string{"-", "\\", "|", "/"}
		t.pulse = []string{"o", "O"}
		t.progress = []string{".", ":", "=", "#"}
		t.check = "[OK]"
		t.cross = "[XX]"
		t.pending = "[ ]"
		t.active = "[*]"
		t.warning = "[!]"
		t.transition = []string{"[ ]", "[.]", "[:]", "[=]", "[#]", "[*]"}
	}
	
	// Set up colors
	if t.colorSupport {
		t.green = "\033[32m"
		t.yellow = "\033[33m"
		t.red = "\033[31m"
		t.blue = "\033[34m"
		t.bold = "\033[1m"
		t.dim = "\033[2m"
		t.reset = "\033[0m"
	}
	
	return t
}

func isTerminal() bool {
	if fileInfo, _ := os.Stdout.Stat(); (fileInfo.Mode() & os.ModeCharDevice) != 0 {
		return true
	}
	return false
}

// ============================================================================
// SERVER MONITOR
// ============================================================================

type ServerStatus struct {
	container string
	bepinex   string
	network   string
	ready     string
	modCount  int
}

type ValheimServerMonitor struct {
	term          *TerminalCapabilities
	timeout       time.Duration
	pollInterval  time.Duration
	startTime     time.Time
	frame         int
	
	containerName string
	workspaceDir  string
	expectedMods  int
	sshCmd        string
	
	status ServerStatus
}

func NewValheimServerMonitor(timeout, pollInterval time.Duration) *ValheimServerMonitor {
	m := &ValheimServerMonitor{
		term:         NewTerminalCapabilities(),
		timeout:      timeout,
		pollInterval: pollInterval,
		startTime:    time.Now(),
		frame:        0,
		sshCmd:       os.ExpandEnv("$HOME/.dotfiles/bin/ssh_windows_wsl"),
		status: ServerStatus{
			container: "pending",
			bepinex:   "pending",
			network:   "pending",
			ready:     "pending",
		},
	}
	
	m.loadConfig()
	m.expectedMods = m.getExpectedModCount()
	
	return m
}

func (m *ValheimServerMonitor) loadConfig() {
	// Load .env file
	if file, err := os.Open(".env"); err == nil {
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			line := scanner.Text()
			if !strings.HasPrefix(line, "#") && strings.Contains(line, "=") {
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					os.Setenv(parts[0], parts[1])
				}
			}
		}
	}
	
	m.containerName = getEnvOrDefault("CONTAINER_NAME", "valheim-server")
	m.workspaceDir = getEnvOrDefault("WORKSPACE_DIR", "/mnt/e/deep.space.10")
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func (m *ValheimServerMonitor) getExpectedModCount() int {
	manifestPath := "./src/modpack/manifest.json"
	file, err := os.Open(manifestPath)
	if err != nil {
		return 0
	}
	defer file.Close()
	
	var manifest struct {
		Mods []interface{} `json:"mods"`
	}
	
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&manifest); err != nil {
		return 0
	}
	
	return len(manifest.Mods)
}

func (m *ValheimServerMonitor) sshExec(command string) string {
	cmd := exec.Command(m.sshCmd, "--command", command)
	output, err := cmd.Output()
	if err != nil {
		return ""
	}
	
	// Extract actual output after SSH tool messages
	lines := strings.Split(string(output), "\n")
	actualOutput := []string{}
	lastExec := -1
	
	for i, line := range lines {
		if strings.HasPrefix(line, "🚀 Executing command") {
			lastExec = i
		}
	}
	
	if lastExec >= 0 && lastExec+1 < len(lines) {
		actualOutput = lines[lastExec+1:]
	}
	
	return strings.Join(actualOutput, "\n")
}

func (m *ValheimServerMonitor) batchSSHExec(commands map[string]string) map[string]string {
	// Build combined command
	var parts []string
	for key, cmd := range commands {
		parts = append(parts, fmt.Sprintf("echo '___MARKER_%s___'; %s; echo '___END_%s___'", key, cmd, key))
	}
	
	fullCommand := strings.Join(parts, "; ")
	output := m.sshExec(fullCommand)
	
	// Parse results
	results := make(map[string]string)
	var currentKey string
	var currentLines []string
	
	markerRe := regexp.MustCompile(`___MARKER_(.+)___`)
	endRe := regexp.MustCompile(`___END_(.+)___`)
	
	for _, line := range strings.Split(output, "\n") {
		if matches := markerRe.FindStringSubmatch(line); matches != nil {
			currentKey = matches[1]
			currentLines = []string{}
		} else if matches := endRe.FindStringSubmatch(line); matches != nil {
			if currentKey != "" {
				results[currentKey] = strings.Join(currentLines, "\n")
			}
			currentKey = ""
		} else if currentKey != "" {
			currentLines = append(currentLines, line)
		}
	}
	
	return results
}

func (m *ValheimServerMonitor) checkAllStatus() {
	commands := map[string]string{
		"container":   fmt.Sprintf("docker ps --filter name=%s --format '{{.Status}}'", m.containerName),
		"mods":        fmt.Sprintf("docker logs %s 2>&1 | grep -c 'Loading \\[' || echo 0", m.containerName),
		"port_27500":  "ss -tlnp 2>/dev/null | grep :27500 || echo ''",
		"port_27501":  "ss -tlnp 2>/dev/null | grep :27501 || echo ''",
		"port_27502":  "ss -tlnp 2>/dev/null | grep :27502 || echo ''",
		"ready":       fmt.Sprintf("docker logs --tail 50 %s 2>&1 | grep 'Game server connected' || echo ''", m.containerName),
	}
	
	results := m.batchSSHExec(commands)
	
	// Update container status
	if strings.Contains(results["container"], "Up") {
		m.status.container = "ready"
	} else if results["container"] != "" {
		m.status.container = "active"
	} else {
		m.status.container = "failed"
	}
	
	// Update mod count
	if modStr := strings.TrimSpace(results["mods"]); modStr != "" {
		for _, line := range strings.Split(modStr, "\n") {
			if count, err := strconv.Atoi(strings.TrimSpace(line)); err == nil {
				m.status.modCount = count
				m.status.bepinex = "active"
				if m.expectedMods > 0 && count >= m.expectedMods {
					m.status.bepinex = "ready"
				} else if count > 40 { // Assume ready if many mods loaded
					m.status.bepinex = "ready"
				}
				break
			}
		}
	}
	
	// Check network
	portsReady := 0
	for _, port := range []string{"port_27500", "port_27501", "port_27502"} {
		// Check for either LISTEN or port number (fallback)
		if strings.Contains(results[port], "LISTEN") || strings.Contains(results[port], port[5:]) {
			portsReady++
		}
	}
	
	// If we can't detect ports but server is ready, assume network is ready
	if portsReady == 3 || (portsReady == 0 && m.status.container == "ready") {
		m.status.network = "ready"
	} else if portsReady > 0 {
		m.status.network = "active"
	}
	
	// Check if server ready
	if strings.Contains(results["ready"], "Game server connected") {
		m.status.ready = "ready"
	} else if m.status.container == "ready" {
		m.status.ready = "active"
	}
}

func (m *ValheimServerMonitor) buildProgressBar(current, total, width int) string {
	if total == 0 {
		return ""
	}
	
	filled := (current * width) / total
	bar := ""
	for i := 0; i < width; i++ {
		if i < filled {
			bar += m.term.progress[3]
		} else {
			bar += m.term.progress[0]
		}
	}
	return bar
}

func (m *ValheimServerMonitor) formatStatus(status, label, extra string) string {
	t := m.term
	
	switch status {
	case "pending":
		return fmt.Sprintf("[%s: %s]", label, t.pending)
	case "active":
		switch label {
		case "Container":
			return fmt.Sprintf("[%s: %s]", label, t.spinner[m.frame%len(t.spinner)])
		case "BepInEx":
			if extra != "" {
				return fmt.Sprintf("[%s: %s]", label, extra)
			}
			return fmt.Sprintf("[%s: %s]", label, t.active)
		case "Network":
			return fmt.Sprintf("[%s: %s]", label, t.pulse[m.frame%len(t.pulse)])
		case "Ready":
			return fmt.Sprintf("[%s: %s]", label, t.transition[m.frame%len(t.transition)])
		default:
			return fmt.Sprintf("[%s: %s]", label, t.active)
		}
	case "ready":
		if extra != "" {
			return fmt.Sprintf("[%s: %s%s%s %s]", label, t.green, t.check, t.reset, extra)
		}
		return fmt.Sprintf("[%s: %s%s%s]", label, t.green, t.check, t.reset)
	case "failed":
		return fmt.Sprintf("[%s: %s%s%s]", label, t.red, t.cross, t.reset)
	}
	return fmt.Sprintf("[%s: ?]", label)
}

func (m *ValheimServerMonitor) displayStatus() {
	// Build BepInEx extra info
	bepinexExtra := ""
	if m.status.bepinex == "active" {
		if m.expectedMods > 0 {
			bar := m.buildProgressBar(m.status.modCount, m.expectedMods, 10)
			bepinexExtra = fmt.Sprintf("%s %d/%d", bar, m.status.modCount, m.expectedMods)
		} else {
			bepinexExtra = fmt.Sprintf("%s %d mods", m.term.spinner[m.frame%len(m.term.spinner)], m.status.modCount)
		}
	} else if m.status.bepinex == "ready" {
		bepinexExtra = fmt.Sprintf("%d mods", m.status.modCount)
	}
	
	// Build status line
	parts := []string{
		"Waiting for server to load..",
		m.formatStatus(m.status.container, "Container", ""),
		m.formatStatus(m.status.bepinex, "BepInEx", bepinexExtra),
		m.formatStatus(m.status.network, "Network", ""),
		m.formatStatus(m.status.ready, "Ready", ""),
	}
	
	statusLine := strings.Join(parts, " ")
	
	// Clear line and print
	fmt.Printf("\r%*s\r%s", m.term.width, "", statusLine)
}

func (m *ValheimServerMonitor) displayCountdown(remaining time.Duration) {
	minutes := int(remaining.Minutes())
	seconds := int(remaining.Seconds()) % 60
	
	countdown := fmt.Sprintf("... Waiting %d seconds.. Time till timeout: %d minutes %d seconds",
		int(m.pollInterval.Seconds()), minutes, seconds)
	
	// Move to next line, print, return
	fmt.Printf("\n%*s\r%s\033[A\r", m.term.width, "", countdown)
}

func (m *ValheimServerMonitor) isReady() bool {
	return m.status.container == "ready" &&
		m.status.bepinex == "ready" &&
		m.status.network == "ready" &&
		m.status.ready == "ready"
}

func (m *ValheimServerMonitor) Run() int {
	// Hide cursor
	if isTerminal() {
		fmt.Print("\033[?25l")
		defer fmt.Print("\033[?25h\n")
	}
	
	// Header
	t := m.term
	fmt.Printf("%s╔══════════════════════════════════════════════╗%s\n", t.bold, t.reset)
	fmt.Printf("%s║      Valheim Server Startup Monitor          ║%s\n", t.bold, t.reset)
	fmt.Printf("%s╚══════════════════════════════════════════════╝%s\n", t.bold, t.reset)
	fmt.Println()
	
	for {
		elapsed := time.Since(m.startTime)
		remaining := m.timeout - elapsed
		
		// Check timeout
		if elapsed >= m.timeout {
			fmt.Printf("\n%s%s Timeout reached after %s%s\n", t.red, t.cross, m.timeout, t.reset)
			return 1
		}
		
		// Check all status
		m.checkAllStatus()
		
		// Update display
		m.displayStatus()
		
		// Check if ready
		if m.isReady() {
			fmt.Printf("\n%s%s Server is ready!%s\n", t.green, t.check, t.reset)
			return 0
		}
		
		// Show countdown and wait
		m.displayCountdown(remaining)
		time.Sleep(m.pollInterval)
		
		// Increment frame
		m.frame++
	}
}

// ============================================================================
// JSON OUTPUT
// ============================================================================

type JSONStatus struct {
	Timestamp    string `json:"timestamp"`
	Status       struct {
		Container string `json:"container"`
		BepInEx   string `json:"bepinex"`
		Network   string `json:"network"`
		Ready     string `json:"ready"`
	} `json:"status"`
	ModCount     int    `json:"mod_count"`
	ExpectedMods int    `json:"expected_mods"`
	ElapsedSecs  int    `json:"elapsed_seconds"`
	Success      bool   `json:"success"`
	Error        string `json:"error,omitempty"`
}

// ============================================================================
// MAIN
// ============================================================================

func main() {
	// Command-line flags
	var (
		timeoutSecs  = flag.Int("timeout", 30, "Timeout in seconds (default: 30 for testing)")
		pollInterval = flag.Int("poll", 5, "Poll interval in seconds")
		jsonOutput   = flag.Bool("json", false, "Output in JSON format")
		_ = flag.Bool("verbose", false, "Verbose output") // Reserved for future use
		maxLines     = flag.Int("max-lines", 20, "Maximum output lines for agentic tools")
		containerName = flag.String("container", "", "Docker container name (default: from .env or valheim-server)")
		sshCmd       = flag.String("ssh", "", "SSH command path (default: ~/.dotfiles/bin/ssh_windows_wsl)")
	)
	
	flag.Parse()
	
	// Convert timeout to duration
	timeout := time.Duration(*timeoutSecs) * time.Second
	poll := time.Duration(*pollInterval) * time.Second
	
	// Create monitor
	monitor := NewValheimServerMonitor(timeout, poll)
	
	// Override settings from flags
	if *containerName != "" {
		monitor.containerName = *containerName
	}
	if *sshCmd != "" {
		monitor.sshCmd = *sshCmd
	}
	
	// Handle JSON output mode
	if *jsonOutput {
		runJSONMode(monitor, *maxLines)
	} else {
		// Set up signal handling for cleanup
		c := make(chan os.Signal, 1)
		signal.Notify(c, os.Interrupt, syscall.SIGTERM)
		go func() {
			<-c
			if isTerminal() {
				fmt.Print("\033[?25h\n") // Show cursor
			}
			os.Exit(1)
		}()
		
		os.Exit(monitor.Run())
	}
}

func runJSONMode(monitor *ValheimServerMonitor, maxLines int) {
	startTime := time.Now()
	outputCount := 0
	
	for {
		elapsed := time.Since(startTime)
		
		// Check timeout
		if elapsed >= monitor.timeout {
			outputJSON(monitor, startTime, false, "Timeout reached")
			os.Exit(1)
		}
		
		// Check status
		monitor.checkAllStatus()
		
		// Output JSON status (limited by maxLines)
		if outputCount < maxLines {
			outputJSON(monitor, startTime, false, "")
			outputCount++
		}
		
		// Check if ready
		if monitor.isReady() {
			outputJSON(monitor, startTime, true, "")
			os.Exit(0)
		}
		
		// Wait
		time.Sleep(monitor.pollInterval)
		monitor.frame++
	}
}

func outputJSON(monitor *ValheimServerMonitor, startTime time.Time, success bool, errorMsg string) {
	status := JSONStatus{
		Timestamp: time.Now().Format(time.RFC3339),
		ModCount: monitor.status.modCount,
		ExpectedMods: monitor.expectedMods,
		ElapsedSecs: int(time.Since(startTime).Seconds()),
		Success: success,
		Error: errorMsg,
	}
	
	status.Status.Container = monitor.status.container
	status.Status.BepInEx = monitor.status.bepinex
	status.Status.Network = monitor.status.network
	status.Status.Ready = monitor.status.ready
	
	data, _ := json.Marshal(status)
	fmt.Println(string(data))
}