#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#define HOST "www.example.com"
#define PORT "443"
#define ITERATIONS 5  // 통신 시도 횟수

void handle_error(const char *msg) {
    perror(msg);
    ERR_print_errors_fp(stderr);
    exit(EXIT_FAILURE);
}

void perform_https_request(SSL_CTX *ctx, const char *ciphersuite) {
    SSL *ssl;
    BIO *bio;
    int ret;

    // 선택한 ciphersuite를 설정합니다.
    if (ciphersuite && SSL_CTX_set_ciphersuites(ctx, ciphersuite) != 1) {
        handle_error("SSL_CTX_set_ciphersuites");
    }

    ssl = SSL_new(ctx);
    if (!ssl) handle_error("SSL_new");

    bio = BIO_new_ssl_connect(ctx);
    if (!bio) handle_error("BIO_new_ssl_connect");

    BIO_set_conn_hostname(bio, HOST ":" PORT);
    if (BIO_do_connect(bio) <= 0) handle_error("BIO_do_connect");

    BIO_get_ssl(bio, &ssl);
    if (!ssl) handle_error("BIO_get_ssl");

    if (BIO_do_handshake(bio) <= 0) handle_error("BIO_do_handshake");
/*
    if (SSL_get_verify_result(ssl) != X509_V_OK) {
        fprintf(stderr, "Server certificate verification failed\n");
    }
*/
    char *request = "GET / HTTP/1.1\r\nHost: " HOST "\r\nConnection: close\r\n\r\n";
    ret = BIO_write(bio, request, strlen(request));
    if (ret <= 0) handle_error("BIO_write");

    char response[1024];
    int bytes_received;
    while ((bytes_received = BIO_read(bio, response, sizeof(response) - 1)) > 0) {
        response[bytes_received] = '\0';
        //printf("%s", response);
    }

    BIO_free_all(bio);
}

int main(int argc, char *argv[]) {
    SSL_CTX *ctx;
    const char *ciphersuite = NULL;

    if (argc > 1) {
        ciphersuite = argv[1]; // 첫 번째 인자를 ciphersuite로 설정
    }

    SSL_library_init();
    OpenSSL_add_all_algorithms();
    SSL_load_error_strings();

    ctx = SSL_CTX_new(TLS_client_method());
    if (!ctx) handle_error("SSL_CTX_new");

    printf("Using ciphersuite: %s\n", ciphersuite ? ciphersuite : "default");
    for (int i = 0; i < ITERATIONS; i++) {
        printf("Iteration %d:\n", i + 1);
        perform_https_request(ctx, ciphersuite);
        printf("\n");
        sleep(2);  // 2초 대기
    }

    SSL_CTX_free(ctx);
    EVP_cleanup();

    return 0;
}

