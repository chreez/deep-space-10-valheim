#!/usr/bin/env python3
"""
Simulate external access test for Valheim server
Tests connectivity as if accessing from outside the network
"""

import socket
import subprocess
import json
import time
import sys

def get_public_ip():
    """Get the public IP address"""
    try:
        result = subprocess.run(['curl', '-s', 'ifconfig.me'], 
                              capture_output=True, text=True)
        return result.stdout.strip()
    except:
        return None

def test_port_timeout(host, port, timeout=5):
    """Test if UDP port responds with various timeout strategies"""
    print(f"\n🔌 Testing port {port} with timeout strategy...")
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    
    try:
        # Send multiple packets to increase chance of response
        for i in range(3):
            sock.sendto(b'ping', (host, port))
            time.sleep(0.1)
        
        # Try to receive any response
        try:
            data, addr = sock.recvfrom(1024)
            print(f"   ✅ Port {port}: Received response!")
            return True
        except socket.timeout:
            print(f"   ⏱️  Port {port}: No response (timeout)")
            return False
            
    except Exception as e:
        print(f"   ❌ Port {port}: Error - {e}")
        return False
    finally:
        sock.close()

def test_server_info(host):
    """Get detailed server information if accessible"""
    print(f"\n📋 Attempting to get server info from {host}...")
    
    # Try to connect to the server's web interface if it has one
    # Some Valheim servers expose metrics
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        # Try common web ports
        for port in [80, 8080, 9090]:
            try:
                sock.connect((host, port))
                print(f"   📡 Found web service on port {port}")
                sock.close()
                break
            except:
                pass
    except:
        pass

def simulate_external_test(target_ip):
    """Simulate what an external client would see"""
    print(f"\n🌍 SIMULATING EXTERNAL ACCESS TEST")
    print(f"   Target: {target_ip}")
    print("   " + "="*40)
    
    # Test each Valheim port
    ports = {
        27500: "Game Port (Main)",
        27501: "Query Port (Server Browser)",
        27502: "Steam Port (Authentication)"
    }
    
    results = {}
    for port, description in ports.items():
        print(f"\n   Testing {description}...")
        results[port] = test_port_timeout(target_ip, port)
    
    # Summary
    print(f"\n📊 EXTERNAL ACCESS SUMMARY:")
    print("   " + "-"*40)
    
    accessible = sum(1 for r in results.values() if r)
    
    for port, description in ports.items():
        status = "✅ Accessible" if results[port] else "❌ Not accessible"
        print(f"   Port {port} ({description}): {status}")
    
    print(f"\n   Overall: {accessible}/3 ports accessible externally")
    
    if accessible == 3:
        print("   ✅ Server appears fully accessible from external networks!")
    elif accessible > 0:
        print("   ⚠️  Partial accessibility - some ports may be blocked")
    else:
        print("   ❌ Server not accessible externally - check:")
        print("      1. Windows Firewall rules")
        print("      2. Router port forwarding")
        print("      3. ISP blocking")
    
    return results

def main():
    print("🔍 Valheim Server External Access Tester")
    print("="*50)
    
    # Get public IP
    public_ip = get_public_ip()
    if public_ip:
        print(f"📍 Your public IP: {public_ip}")
        print("   (Players would connect to this IP)")
    
    # Test local first
    print("\n1️⃣ LOCAL NETWORK TEST (192.168.1.236)")
    local_results = simulate_external_test("192.168.1.236")
    
    # Provide instructions for real external test
    print("\n2️⃣ ACTUAL EXTERNAL TEST")
    print("   To truly test external access:")
    print(f"   - From another network, run: python test_server_query.py {public_ip}")
    print("   - Or use: https://www.yougetsignal.com/tools/open-ports/")
    print(f"   - Test ports: 27500-27502 UDP on IP: {public_ip}")
    
    # Test via command line argument
    if len(sys.argv) > 1:
        test_ip = sys.argv[1]
        print(f"\n3️⃣ TESTING SPECIFIC IP: {test_ip}")
        simulate_external_test(test_ip)

if __name__ == "__main__":
    main()