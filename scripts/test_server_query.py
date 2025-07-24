#!/usr/bin/env python3
"""
Test Valheim server connectivity by sending a Steam A2S_INFO query
This simulates what happens when a player tries to find the server
"""

import socket
import struct
import sys
import time

def test_steam_query(host, port=27501):
    """Send a Steam A2S_INFO query to test server responsiveness"""
    print(f"\n🔍 Testing Steam server query to {host}:{port}")
    
    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(5.0)
    
    try:
        # A2S_INFO query packet
        # Format: 0xFFFFFFFF (4 bytes) + 0x54 (T) + "Source Engine Query\0"
        query = b'\xFF\xFF\xFF\xFF\x54Source Engine Query\x00'
        
        print(f"📤 Sending A2S_INFO query...")
        sock.sendto(query, (host, port))
        
        # Wait for response
        data, addr = sock.recvfrom(4096)
        print(f"📥 Received response from {addr[0]}:{addr[1]} ({len(data)} bytes)")
        
        # Check if it's a valid response
        if len(data) > 4 and data[0:4] == b'\xFF\xFF\xFF\xFF':
            print("✅ Server responded to query!")
            
            # Try to parse some basic info
            if data[4] == 0x49:  # 'I' - A2S_INFO response
                print("📋 Valid A2S_INFO response received")
                # Basic parsing (simplified)
                try:
                    # Skip header and protocol
                    pos = 6
                    # Server name (null-terminated string)
                    name_end = data.find(b'\x00', pos)
                    if name_end > pos:
                        server_name = data[pos:name_end].decode('utf-8', errors='ignore')
                        print(f"   Server Name: {server_name}")
                except:
                    pass
            return True
        else:
            print("❌ Invalid response format")
            return False
            
    except socket.timeout:
        print("❌ Connection timed out - server may not be responding to queries")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    finally:
        sock.close()

def test_game_port(host, port=27500):
    """Test if the game port is open"""
    print(f"\n🎮 Testing game port {host}:{port}")
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2.0)
    
    try:
        # Send a simple UDP packet
        sock.sendto(b'test', (host, port))
        print("✅ UDP packet sent successfully")
        return True
    except Exception as e:
        print(f"❌ Failed to send packet: {e}")
        return False
    finally:
        sock.close()

def test_all_ports(host):
    """Test all Valheim server ports"""
    print(f"🌐 Testing Valheim server at {host}")
    print("=" * 50)
    
    results = {
        "game_port": test_game_port(host, 27500),
        "query_port": test_steam_query(host, 27501),
        "steam_port": test_game_port(host, 27502)
    }
    
    print("\n📊 Summary:")
    print(f"   Game Port (27500):  {'✅ Open' if results['game_port'] else '❌ Blocked'}")
    print(f"   Query Port (27501): {'✅ Responding' if results['query_port'] else '❌ Not responding'}")
    print(f"   Steam Port (27502): {'✅ Open' if results['steam_port'] else '❌ Blocked'}")
    
    if all(results.values()):
        print("\n✅ All ports are accessible - server should be reachable!")
    else:
        print("\n⚠️  Some ports are not accessible - check firewall settings")
    
    return results

if __name__ == "__main__":
    # Test from local network
    print("🏠 LOCAL NETWORK TEST")
    local_results = test_all_ports("192.168.1.236")
    
    # To simulate external access, you could also test via the public IP
    # But this requires knowing the public IP and having port forwarding set up
    print("\n" + "="*60)
    print("\n💡 To test external access:")
    print("   1. Find your public IP: curl ifconfig.me")
    print("   2. Ensure router port forwarding is configured")
    print("   3. Run: python test_server_query.py YOUR_PUBLIC_IP")
    
    if len(sys.argv) > 1:
        print(f"\n🌍 EXTERNAL ACCESS TEST (via {sys.argv[1]})")
        test_all_ports(sys.argv[1])