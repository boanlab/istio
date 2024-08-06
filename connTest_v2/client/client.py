import socket
import sys

def main():
    host = 'echo-server.test'  # 서버의 호스트명 (Docker 네트워크에서 사용)
    port = 8888

    message = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Hello, Server!"

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((host, port))
        print(f"Sending: {message}")
        s.sendall(message.encode())
        data = s.recv(1024)
        print(f"Received: {data.decode()}")

if __name__ == "__main__":
    main()
