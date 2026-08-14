idf_component_register(SRCS "main.c"
                       PRIV_REQUIRES nvs_flash
                       PRIV_REQUIRES esp_wifi
                       PRIV_REQUIRES esp_http_client
                       PRIV_REQUIRES mbedtls
                       INCLUDE_DIRS "")
