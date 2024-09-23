import socket
import struct
import binascii

sniffer = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0003))

def mac_addr(mac_bytes):
    """Convert bytes to a MAC address string."""
    return ':'.join(map('{:02x}'.format, mac_bytes))

def eth_frame(data):
    """Unpack Ethernet frame."""
    dest_mac, src_mac, proto = struct.unpack('!6s6sH', data[:14])
    return mac_addr(dest_mac), mac_addr(src_mac), socket.htons(proto), data[14:]

def ipv4_packet(data):
    """Unpack IPv4 packet."""
    version_header_length = data[0]
    header_length = (version_header_length & 15) * 4
    ttl, proto, src, target = struct.unpack('!8xBB2x4s4s', data[:20])
    return ttl, proto, ipv4(src), ipv4(target), data[header_length:]

def ipv4(addr):
    """Convert bytes to an IPv4 address."""
    return '.'.join(map(str, addr))

def icmp_packet(data):
    """Unpack ICMP packet."""
    icmp_type, code, checksum = struct.unpack('!BBH', data[:4])
    return icmp_type, code, checksum

def tcp_segment(data):
    """Unpack TCP segment."""
    src_port, dest_port, sequence, acknowledgement, offset_reserved_flags = struct.unpack('!HHLLH', data[:14])
    offset = (offset_reserved_flags >> 12) * 4
    return src_port, dest_port, sequence, acknowledgement, data[offset:]

def udp_segment(data):
    """Unpack UDP segment."""
    src_port, dest_port, size = struct.unpack('!HH2xH', data[:8])
    return src_port, dest_port, size

try:
    while True:
        # Receive packets
        raw_packet = sniffer.recvfrom(65565)[0]

        # Get Ethernet frame information
        dest_mac, src_mac, proto, data = eth_frame(raw_packet)
        print(f'\nEthernet Frame:')
        print(f'  - Destination MAC: {dest_mac}, Source MAC: {src_mac}, Protocol: {proto}')

        #Process only IPv4 packets
        if proto == 8:
            ttl, proto, src_ip, dest_ip, data = ipv4_packet(data)
            print(f'  - IPv4 Packet:')
            print(f'    - Source IP: {src_ip}, Destination IP: {dest_ip}, TTL: {ttl}')

            #ICMP
            if proto == 1:
                icmp_type, code, checksum = icmp_packet(data)
                print(f'    - ICMP Packet:')
                print(f'      - Type: {icmp_type}, Code: {code}, Checksum: {checksum}')

            #TCP
            elif proto == 6:
                src_port, dest_port, sequence, acknowledgement, data = tcp_segment(data)
                print(f'    - TCP Segment:')
                print(f'      - Source Port: {src_port}, Destination Port: {dest_port}')
                print(f'      - Sequence: {sequence}, Acknowledgement: {acknowledgement}')

            #UDP
            elif proto == 17:
                src_port, dest_port, length = udp_segment(data)
                print(f'    - UDP Segment:')
                print(f'      - Source Port: {src_port}, Destination Port: {dest_port}, Length: {length}')

except KeyboardInterrupt:
    print("\nSniffer stopped")
