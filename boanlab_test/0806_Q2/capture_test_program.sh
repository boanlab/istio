#!/bin/bash

# root 권한 확인
if [ "$(id -u)" != "0" ]; then
   echo "이 스크립트는 root 권한으로 실행해야 합니다." 1>&2
   exit 1
fi

# 환경 변수에서 프로그램 이름을 가져옵니다. 설정되지 않았다면 기본값을 사용합니다.
PROGRAM=${PROGRAM_NAME:-"./test_TLS_1_3_ciphersuites_config"}

# www.example.com의 IP 주소 찾기
IP=$(nslookup -type=A www.example.com | awk '/^Address: / { print $2 }' | tail -n1)

if [ -z "$IP" ]; then
    echo "IP 주소를 찾을 수 없습니다."
    exit 1
fi

echo "www.example.com의 IP 주소: $IP"

# 로컬 IP 주소 찾기
LOCAL_IP=$(ip route get 1 | awk '{print $7;exit}')

echo "로컬 IP 주소: $LOCAL_IP"

start_tcpdump() {
    echo "패킷 캡처 시작: $1"
    tcpdump -i any host $IP and \(src $LOCAL_IP or dst $LOCAL_IP\) -s 0 -B 4096 -w "$1" 2>/dev/null &
    TCPDUMP_PID=$!
    sleep 2
}

stop_tcpdump() {
    if ps -p $TCPDUMP_PID > /dev/null
    then
        sleep 5  # 프로그램 종료 후 추가 대기 시간
        kill $TCPDUMP_PID
        wait $TCPDUMP_PID 2>/dev/null
    fi
    if [ -f "$1" ]; then
        SUDO_USER=${SUDO_USER:-$USER}
        chown $SUDO_USER:$SUDO_USER "$1"
        echo "패킷 캡처 완료. 결과는 $1 파일에 저장되었습니다."
        # 파일 크기 확인
        file_size=$(du -b "$1" | cut -f1)
        echo "캡처 파일 크기: $file_size bytes"
    else
        echo "오류: 캡처 파일이 생성되지 않았습니다."
    fi
}

# 기본 테스트 (ciphersuites 지정 없음)
CAPTURE_FILE="./capture_default.pcap"
start_tcpdump "$CAPTURE_FILE"
echo "프로그램 실행 (기본 설정): $PROGRAM"
$PROGRAM
stop_tcpdump "$CAPTURE_FILE"

# TLS_AES_128_GCM_SHA256 ciphersuite 사용
CAPTURE_FILE="./capture_aes128.pcap"
export OSSL_CIPHER_SUITE="TLS_AES_128_GCM_SHA256"
start_tcpdump "$CAPTURE_FILE"
echo "프로그램 실행 (TLS_AES_128_GCM_SHA256): $PROGRAM"
$PROGRAM $OSSL_CIPHER_SUITE
stop_tcpdump "$CAPTURE_FILE"
unset OSSL_CIPHER_SUITE

# TLS_CHACHA20_POLY1305_SHA256 ciphersuite 사용
CAPTURE_FILE="./capture_chacha20.pcap"
export OSSL_CIPHER_SUITE="TLS_CHACHA20_POLY1305_SHA256"
start_tcpdump "$CAPTURE_FILE"
echo "프로그램 실행 (TLS_CHACHA20_POLY1305_SHA256): $PROGRAM"
$PROGRAM $OSSL_CIPHER_SUITE
stop_tcpdump "$CAPTURE_FILE"
unset OSSL_CIPHER_SUITE

