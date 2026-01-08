#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        XRAY-CHECKER INSTALLER                                ║
# ║                                                                              ║
# ║  Автоустановщик для xray-checker — мониторинг прокси-серверов                ║
# ║  Поддержка: VLESS, VMess, Trojan, Shadowsocks                                ║
# ║                                                                              ║
# ║  Использование:                                                              ║
# ║    bash <(curl -Ls https://raw.githubusercontent.com/.../install.sh)         ║
# ║                                                                              ║
# ║  Команды после установки:                                                    ║
# ║    xchecker              — открыть меню управления                           ║
# ║    xray_checker_install  — полная команда                                    ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# TODO: Планируемые функции
# ══════════════════════════════════════════════════════════════════════════════
#
# [ ] Prometheus/Grafana/Uptime Kuma Integration (Manage Service → Integrations)
#     ├── [ ] Prometheus — показать готовый scrape config для prometheus.yml
#     ├── [ ] Grafana — инструкция по импорту dashboard + JSON файл
#     ├── [ ] Uptime Kuma — показать endpoints для мониторинга (health, config/{id})
#     └── [ ] Pushgateway — помощник настройки METRICS_PUSH_URL
#
# ══════════════════════════════════════════════════════════════════════════════

set -e

# Принудительная установка UTF-8 локали для корректного отображения Unicode символов
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# ══════════════════════════════════════════════════════════════════════════════
# ВЕРСИЯ И КОНСТАНТЫ
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_VERSION="0.0.1-alpha"
SCRIPT_NAME="install_xray_checker.sh"
SCRIPT_URL="https://raw.githubusercontent.com/UnderGut/xray-checker-installer/main/install_xray_checker.sh"

# Директории
DIR_XRAY_CHECKER="/opt/xray-checker/"
DIR_CERTS="${DIR_XRAY_CHECKER}certs/"

# Файлы конфигурации
FILE_ENV="${DIR_XRAY_CHECKER}.env"
FILE_COMPOSE="${DIR_XRAY_CHECKER}docker-compose.yml"
FILE_LANG="${DIR_XRAY_CHECKER}selected_language"
FILE_METHOD="${DIR_XRAY_CHECKER}install_method"
FILE_API_CONFIG="${DIR_XRAY_CHECKER}api_config.env"

# Docker
DOCKER_IMAGE="kutovoys/xray-checker:latest"
DOCKER_CONTAINER="xray-checker"
DOCKER_NETWORK="remnawave-network"

# Порт по умолчанию
DEFAULT_PORT=2112

# ══════════════════════════════════════════════════════════════════════════════
# СИМВОЛЫ РАМКИ (ASCII для максимальной совместимости)
# ══════════════════════════════════════════════════════════════════════════════

# ASCII символы рамки (работают везде)
BOX_TL="+"
BOX_TR="+"
BOX_BL="+"
BOX_BR="+"
BOX_H="-"
BOX_V="|"
# Предгенерированная линия из 60 символов
BOX_LINE_60="------------------------------------------------------------"

# ══════════════════════════════════════════════════════════════════════════════
# ЦВЕТА
# ══════════════════════════════════════════════════════════════════════════════

COLOR_RESET="\033[0m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_MAGENTA="\033[1;35m"
COLOR_CYAN="\033[1;36m"
COLOR_WHITE="\033[1;37m"
COLOR_GRAY="\033[0;90m"

# ══════════════════════════════════════════════════════════════════════════════
# ФУНКЦИИ РИСОВАНИЯ РАМОК
# ══════════════════════════════════════════════════════════════════════════════

# Верхняя граница рамки
print_box_top() {
    echo -e "${COLOR_GREEN}${BOX_TL}${BOX_LINE_60}${BOX_TR}${COLOR_RESET}"
}

# Нижняя граница рамки
print_box_bottom() {
    echo -e "${COLOR_GREEN}${BOX_BL}${BOX_LINE_60}${BOX_BR}${COLOR_RESET}"
}

# Строка с текстом внутри рамки (центрирование)
print_box_line_text() {
    local text="$1"
    local width=60
    
    # Удаляем ANSI коды для подсчёта длины
    local clean_text
    clean_text=$(printf '%b' "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    
    local padding=$(( (width - text_len) / 2 ))
    local padding_right=$(( width - text_len - padding ))
    
    # Генерируем пробелы через printf
    local spaces_left
    local spaces_right
    spaces_left=$(printf '%*s' "$padding" '')
    spaces_right=$(printf '%*s' "$padding_right" '')
    
    echo -e "${COLOR_GREEN}${BOX_V}${COLOR_RESET}${spaces_left}${text}${spaces_right}${COLOR_GREEN}${BOX_V}${COLOR_RESET}"
}

# Пустая строка внутри рамки
print_box_empty() {
    local width=60
    local spaces
    spaces=$(printf '%*s' "$width" '')
    echo -e "${COLOR_GREEN}${BOX_V}${COLOR_RESET}${spaces}${COLOR_GREEN}${BOX_V}${COLOR_RESET}"
}

# ══════════════════════════════════════════════════════════════════════════════
# ЯЗЫКОВЫЕ СТРОКИ
# ══════════════════════════════════════════════════════════════════════════════

declare -A LANG_EN
declare -A LANG_RU
declare -A LANG

# English
LANG_EN=(
    # General
    [MENU_TITLE]="XRAY-CHECKER INSTALLER"
    [VERSION]="Version"
    [EXIT]="Exit"
    [BACK]="Back"
    [YES]="Yes"
    [NO]="No"
    [OK]="OK"
    [ERROR]="Error"
    [WARNING]="Warning"
    [SUCCESS]="Success"
    [WAITING]="Please wait..."
    [PRESS_ENTER]="Press Enter to continue..."
    [SELECT_OPTION]="Select option"
    [INVALID_OPTION]="Invalid option"
    [RECOMMENDED]="recommended"
    [FIELD_REQUIRED]="This field is required"
    [INVALID_URL]="Invalid URL format"
    [INVALID_NUMBER]="Please enter a valid number"
    [INVALID_YN]="Please enter y or n"

    # Main Menu
    [MENU_QUICK_INSTALL]="Quick Install"
    [MENU_CUSTOM_INSTALL]="Custom Install"
    [MENU_MANAGE]="Manage Service"
    [MENU_UPDATE_SCRIPT]="Update Script"
    [MENU_UNINSTALL]="Uninstall"

    # Installation
    [INSTALL_TITLE]="INSTALLATION"
    [QUICK_INSTALL_DESC]="Just enter subscription URL — we handle the rest!"
    [CUSTOM_INSTALL_DESC]="Advanced settings: port, auth, reverse proxy"
    [ENTER_SUBSCRIPTION_URL]="Enter subscription URL:"
    [ENTER_0_TO_BACK]="Enter 0 to go back"
    [CHOOSE_INSTALL_METHOD]="Choose installation method:"
    [INSTALL_DOCKER]="Docker"
    [INSTALL_BINARY]="Binary (systemd)"
    [ENTER_PORT]="Enter port"
    [ENABLE_AUTH]="Enable Basic Auth protection?"
    [ENABLE_PUBLIC_DASHBOARD]="Enable public dashboard?"

    # Credentials
    [CREDENTIALS_TITLE]="ACCESS CREDENTIALS"
    [USERNAME]="Username"
    [PASSWORD]="Password"
    [CREDENTIALS_HINT]="Save these! You can change them later in .env"
    [CREDENTIALS_FILE]="Credentials stored in"

    # Progress
    [CHECKING_SYSTEM]="Checking system requirements..."
    [INSTALLING_PACKAGES]="Installing required packages..."
    [INSTALLING_DOCKER]="Installing Docker..."
    [CREATING_CONFIG]="Creating configuration..."
    [STARTING_SERVICE]="Starting service..."
    [CHECKING_HEALTH]="Checking service health..."

    # Access Method
    [ACCESS_METHOD_TITLE]="How do you want to access xray-checker?"
    [ACCESS_DIRECT_IP]="Direct access via IP:PORT (HTTP)"
    [ACCESS_DIRECT_IP_DESC]="Simple setup, no domain required"
    [ACCESS_REVERSE_PROXY]="Via domain with HTTPS"
    [ACCESS_REVERSE_PROXY_DESC]="Secure, requires domain and SSL certificate"

    # Success
    [INSTALL_COMPLETE]="INSTALLATION COMPLETE"
    [WEB_INTERFACE]="Web Interface"
    [METRICS_ENDPOINT]="Metrics Endpoint"
    [HEALTH_ENDPOINT]="Health Check"
    [RERUN_CMD]="To reopen this menu, run"
    [HTTP_WARNING]="HTTP is not secure. Setup reverse proxy with HTTPS for production use"
    [HTTPS_RECOMMENDED]="For secure access, configure domain with SSL"

    # Service Management
    [MANAGE_TITLE]="SERVICE MANAGEMENT"
    [SERVICE_START]="Start"
    [SERVICE_STOP]="Stop"
    [SERVICE_RESTART]="Restart"
    [SERVICE_STATUS]="Status"
    [SERVICE_LOGS]="View Logs"
    [SERVICE_UPDATE]="Update Container"
    [SERVICE_EDIT_ENV]="Edit Configuration"
    [SERVICE_RUNNING]="Service is running"
    [SERVICE_STOPPED]="Service is stopped"
    [SERVICE_NOT_INSTALLED]="Service is not installed"

    # Update
    [UPDATE_CHECKING]="Checking for updates..."
    [UPDATE_AVAILABLE]="New version available"
    [UPDATE_CURRENT]="Current version"
    [UPDATE_LATEST]="You have the latest version"
    [UPDATE_CONFIRM]="Update now?"
    [UPDATE_SUCCESS]="Script updated successfully!"
    [UPDATE_RESTART]="Please restart the script"

    # Uninstall
    [UNINSTALL_TITLE]="UNINSTALL"
    [UNINSTALL_CONFIRM]="Are you sure? All data will be removed!"
    [UNINSTALL_COMPLETE]="Uninstall complete"

    # Errors
    [ERROR_ROOT]="This script must be run as root"
    [ERROR_OS]="Unsupported OS. Requires Debian 11/12 or Ubuntu 22.04/24.04"
    [ERROR_DOCKER]="Docker installation failed"
    [ERROR_HEALTH]="Service health check failed"

    # Reverse Proxy
    [PROXY_TITLE]="REVERSE PROXY SETUP"
    [PROXY_DETECTED]="Detected"
    [PROXY_NONE]="No reverse proxy detected"
    [PROXY_SKIP]="Skip (use IP:PORT directly)"
    [PROXY_CADDY]="Install Caddy (auto SSL)"
    [PROXY_NGINX]="Install Nginx"
    [PROXY_USE_EXISTING]="Use existing"
    [PROXY_ENTER_DOMAIN]="Enter domain for xray-checker:"

    # Subscription
    [SUB_MODE_TITLE]="SUBSCRIPTION SOURCE"
    [SUB_MANUAL]="Enter URL manually"
    [SUB_API]="Remnawave API (auto-create user)"
    [SUB_ENTER_PANEL_URL]="Enter panel URL (e.g. https://panel.example.com):"
    [SUB_ENTER_API_TOKEN]="Enter API token:"
    [SUB_USER_FOUND]="User found"
    [SUB_USER_CREATED]="User created"
    [SUBSCRIPTION_CONFIGURED]="Subscription configured"

    # Remnawave API
    [API_DESCRIPTION]="Automatically create user in Remnawave panel"
    [API_USERNAME]="XrayChecker"
    [API_USER_PREFIX]="User"
    [API_TOKEN_HINT_TITLE]="How to get API token:"
    [API_TOKEN_HINT_1]="1. Open Remnawave panel in browser"
    [API_TOKEN_HINT_2]="2. In sidebar: Remnawave Settings -> API Tokens"
    [API_TOKEN_HINT_3]="3. Click 'Create API Token'"
    [API_TOKEN_HINT_4]="4. Copy the generated token"
    [API_TOKEN_CONFIRM]="Is this API token correct?"
    [API_INSTALL_TYPE]="How is Remnawave panel installed?"
    [API_INSTALL_OFFICIAL]="Official documentation (no cookie protection)"
    [API_INSTALL_EGAMES]="eGames script (with cookie protection)"
    [API_EXTRACTING_COOKIE]="Searching for cookie in nginx.conf..."
    [API_COOKIE_NOT_FOUND]="Cookie not found automatically"
    [API_COOKIE_INFO]="eGames installation uses nginx cookie protection"
    [API_COOKIE_HINT]="SSH: grep -A2 'map \$http_cookie' /opt/remnawave/nginx.conf"
    [API_ENTER_COOKIE_NAME]="Enter cookie name:"
    [API_ENTER_COOKIE_VALUE]="Enter cookie value:"
    [API_CHECKING_USER]="Checking XrayChecker user..."
    [API_USER_FOUND]="User XrayChecker found"
    [API_CREATING_USER]="Creating XrayChecker user..."
    [API_USER_CREATED]="User XrayChecker created"
    [API_SUCCESS]="Subscription obtained via API"
    [API_FAILED]="Failed to get subscription via API"
    [API_FALLBACK_MANUAL]="Enter subscription URL manually?"
    [API_ERROR]="API Error"

    # SSL Certificates
    [SSL_TITLE]="SSL CERTIFICATE SETUP"
    [SSL_DOMAIN]="Domain"
    [SSL_EXISTING_FOUND]="Existing certificates found"
    [SSL_CLOUDFLARE]="Cloudflare DNS-01"
    [SSL_CF_DESC]="Requires API token, supports wildcard"
    [SSL_ACME]="ACME HTTP-01 (standalone)"
    [SSL_ACME_DESC]="Port 80 must be free"
    [SSL_GCORE]="Gcore DNS API"
    [SSL_GCORE_DESC]="Requires API token, supports wildcard"
    [SSL_USE_EXISTING]="Use existing certificate"
    [SSL_EXISTING]="Use existing certificate"
    [SSL_CERTS_FOUND]="Existing certificates found:"
    [SSL_OBTAIN_NEW]="Obtain new certificate"
    [SSL_SKIP]="Skip SSL setup"
    [SSL_ENTER_CF_TOKEN]="Enter Cloudflare API Token:"
    [SSL_ENTER_GCORE_TOKEN]="Enter Gcore API Token:"
    [SSL_ENTER_EMAIL]="Enter email for Let's Encrypt:"
    [SSL_SELECT_CERT]="Select certificate"
    [SSL_ENTER_CERT_NUM]="Enter number:"
    [SSL_INSTALLING_CERTBOT]="Installing certbot..."
    [SSL_INSTALLING_CF_PLUGIN]="Installing Cloudflare plugin..."
    [SSL_INSTALLING_GCORE_PLUGIN]="Installing Gcore plugin..."
    [SSL_OBTAINING_CERT]="Obtaining certificate"
    [SSL_CERT_OBTAINED]="Certificate obtained successfully"
    [SSL_CERT_FAILED]="Failed to obtain certificate"
    [SSL_PORT80_BUSY]="Port 80 is in use, trying to free it..."
    [SSL_RENEWAL_ENABLED]="Auto-renewal enabled"

    # Binary Installation
    [BINARY_DETECTING_ARCH]="Detecting architecture"
    [BINARY_DOWNLOADING]="Downloading xray-checker"
    [BINARY_INSTALLED]="Binary installed"
    [BINARY_INSTALLING]="Installing xray-checker (binary)..."
    [BINARY_CREATING_USER]="Creating system user"
    [BINARY_USER_EXISTS]="User already exists"
    [BINARY_SERVICE_CREATED]="Systemd service created"
    [BINARY_UPDATING]="Updating xray-checker..."
    [BINARY_UPDATED]="Binary updated"
    [BINARY_UNINSTALLING]="Uninstalling binary..."
    [BINARY_UNINSTALLED]="Binary uninstalled"
    [ERROR_UNSUPPORTED_ARCH]="Unsupported architecture"
    [ERROR_FETCH_RELEASE]="Failed to fetch release info"
    [ERROR_NO_BINARY]="No binary found for"
    [ERROR_DOWNLOAD_BINARY]="Failed to download binary"
    [ERROR_UNKNOWN_FORMAT]="Unknown archive format"
    [ERROR_BINARY_NOT_FOUND]="Binary not found in archive"
)

# Russian
LANG_RU=(
    # Общее
    [MENU_TITLE]="УСТАНОВЩИК XRAY-CHECKER"
    [VERSION]="Версия"
    [EXIT]="Выход"
    [BACK]="Назад"
    [YES]="Да"
    [NO]="Нет"
    [OK]="OK"
    [ERROR]="Ошибка"
    [WARNING]="Внимание"
    [SUCCESS]="Успешно"
    [WAITING]="Пожалуйста, подождите..."
    [PRESS_ENTER]="Нажмите Enter для продолжения..."
    [SELECT_OPTION]="Выберите вариант"
    [INVALID_OPTION]="Неверный вариант"
    [RECOMMENDED]="рекомендуется"
    [FIELD_REQUIRED]="Это поле обязательно"
    [INVALID_URL]="Неверный формат URL"
    [INVALID_NUMBER]="Введите корректное число"
    [INVALID_YN]="Введите y или n"

    # Главное меню
    [MENU_QUICK_INSTALL]="Быстрая установка"
    [MENU_CUSTOM_INSTALL]="Расширенная установка"
    [MENU_MANAGE]="Управление сервисом"
    [MENU_UPDATE_SCRIPT]="Обновить скрипт"
    [MENU_UNINSTALL]="Удаление"

    # Установка
    [INSTALL_TITLE]="УСТАНОВКА"
    [QUICK_INSTALL_DESC]="Просто введите URL подписки — мы сделаем всё!"
    [CUSTOM_INSTALL_DESC]="Расширенные настройки: порт, авторизация, reverse proxy"
    [ENTER_SUBSCRIPTION_URL]="Введите URL подписки:"
    [ENTER_0_TO_BACK]="Введите 0 для выхода"
    [CHOOSE_INSTALL_METHOD]="Выберите метод установки:"
    [INSTALL_DOCKER]="Docker"
    [INSTALL_BINARY]="Binary (systemd)"
    [ENTER_PORT]="Введите порт"
    [ENABLE_AUTH]="Включить Basic Auth защиту?"
    [ENABLE_PUBLIC_DASHBOARD]="Включить публичный дашборд?"

    # Учётные данные
    [CREDENTIALS_TITLE]="ДАННЫЕ ДЛЯ ДОСТУПА"
    [USERNAME]="Логин"
    [PASSWORD]="Пароль"
    [CREDENTIALS_HINT]="Сохраните их! Изменить можно в .env"
    [CREDENTIALS_FILE]="Данные сохранены в"

    # Прогресс
    [CHECKING_SYSTEM]="Проверка системных требований..."
    [INSTALLING_PACKAGES]="Установка необходимых пакетов..."
    [INSTALLING_DOCKER]="Установка Docker..."
    [CREATING_CONFIG]="Создание конфигурации..."
    [STARTING_SERVICE]="Запуск сервиса..."
    [CHECKING_HEALTH]="Проверка состояния сервиса..."

    # Способ доступа
    [ACCESS_METHOD_TITLE]="Как вы хотите получать доступ к xray-checker?"
    [ACCESS_DIRECT_IP]="Напрямую по IP:PORT (HTTP)"
    [ACCESS_DIRECT_IP_DESC]="Простая настройка, домен не нужен"
    [ACCESS_REVERSE_PROXY]="Через домен с HTTPS"
    [ACCESS_REVERSE_PROXY_DESC]="Безопасно, требуется домен и SSL сертификат"

    # Успех
    [INSTALL_COMPLETE]="УСТАНОВКА ЗАВЕРШЕНА"
    [WEB_INTERFACE]="Веб-интерфейс"
    [METRICS_ENDPOINT]="Метрики"
    [HEALTH_ENDPOINT]="Health Check"
    [RERUN_CMD]="Для повторного запуска меню"
    [HTTP_WARNING]="HTTP небезопасен. Настройте reverse proxy с HTTPS для продакшена"
    [HTTPS_RECOMMENDED]="Для безопасного доступа настройте домен с SSL"

    # Управление сервисом
    [MANAGE_TITLE]="УПРАВЛЕНИЕ СЕРВИСОМ"
    [SERVICE_START]="Запустить"
    [SERVICE_STOP]="Остановить"
    [SERVICE_RESTART]="Перезапустить"
    [SERVICE_STATUS]="Статус"
    [SERVICE_LOGS]="Просмотр логов"
    [SERVICE_UPDATE]="Обновить контейнер"
    [SERVICE_EDIT_ENV]="Редактировать конфигурацию"
    [SERVICE_RUNNING]="Сервис запущен"
    [SERVICE_STOPPED]="Сервис остановлен"
    [SERVICE_NOT_INSTALLED]="Сервис не установлен"

    # Обновление
    [UPDATE_CHECKING]="Проверка обновлений..."
    [UPDATE_AVAILABLE]="Доступна новая версия"
    [UPDATE_CURRENT]="Текущая версия"
    [UPDATE_LATEST]="У вас последняя версия"
    [UPDATE_CONFIRM]="Обновить сейчас?"
    [UPDATE_SUCCESS]="Скрипт успешно обновлён!"
    [UPDATE_RESTART]="Перезапустите скрипт"

    # Удаление
    [UNINSTALL_TITLE]="УДАЛЕНИЕ"
    [UNINSTALL_CONFIRM]="Вы уверены? Все данные будут удалены!"
    [UNINSTALL_COMPLETE]="Удаление завершено"

    # Ошибки
    [ERROR_ROOT]="Скрипт должен быть запущен от root"
    [ERROR_OS]="Неподдерживаемая ОС. Требуется Debian 11/12 или Ubuntu 22.04/24.04"
    [ERROR_DOCKER]="Ошибка установки Docker"
    [ERROR_HEALTH]="Ошибка проверки сервиса"

    # Reverse Proxy
    [PROXY_TITLE]="НАСТРОЙКА REVERSE PROXY"
    [PROXY_DETECTED]="Обнаружен"
    [PROXY_NONE]="Reverse proxy не обнаружен"
    [PROXY_SKIP]="Пропустить (использовать IP:PORT)"
    [PROXY_CADDY]="Установить Caddy (авто SSL)"
    [PROXY_NGINX]="Установить Nginx"
    [PROXY_USE_EXISTING]="Использовать существующий"
    [PROXY_ENTER_DOMAIN]="Введите домен для xray-checker:"

    # Подписка
    [SUB_MODE_TITLE]="ИСТОЧНИК ПОДПИСКИ"
    [SUB_MANUAL]="Ввести URL вручную"
    [SUB_API]="Remnawave API (авто-создание пользователя)"
    [SUB_ENTER_PANEL_URL]="Введите URL панели (например, https://panel.example.com):"
    [SUB_ENTER_API_TOKEN]="Введите API токен:"
    [SUB_USER_FOUND]="Пользователь найден"
    [SUB_USER_CREATED]="Пользователь создан"
    [SUBSCRIPTION_CONFIGURED]="Подписка настроена"

    # Remnawave API
    [API_DESCRIPTION]="Автоматическое создание пользователя в панели Remnawave"
    [API_USERNAME]="XrayChecker"
    [API_USER_PREFIX]="Пользователь"
    [API_TOKEN_HINT_TITLE]="Как получить API токен:"
    [API_TOKEN_HINT_1]="1. Откройте панель Remnawave в браузере"
    [API_TOKEN_HINT_2]="2. В боковом меню: Настройки Remnawave -> API токены"
    [API_TOKEN_HINT_3]="3. Нажмите 'Создать API токен'"
    [API_TOKEN_HINT_4]="4. Скопируйте сгенерированный токен"
    [API_TOKEN_CONFIRM]="Этот API токен верный?"
    [API_INSTALL_TYPE]="Как установлена панель Remnawave?"
    [API_INSTALL_OFFICIAL]="Официальная документация (без cookie-защиты)"
    [API_INSTALL_EGAMES]="Скрипт eGames (с cookie-защитой)"
    [API_EXTRACTING_COOKIE]="Поиск cookie в nginx.conf..."
    [API_COOKIE_NOT_FOUND]="Cookie не найдены автоматически"
    [API_COOKIE_INFO]="Установка eGames использует cookie-защиту nginx"
    [API_COOKIE_HINT]="SSH: grep -A2 'map \$http_cookie' /opt/remnawave/nginx.conf"
    [API_ENTER_COOKIE_NAME]="Введите имя cookie:"
    [API_ENTER_COOKIE_VALUE]="Введите значение cookie:"
    [API_CHECKING_USER]="Проверка пользователя XrayChecker..."
    [API_USER_FOUND]="Пользователь XrayChecker найден"
    [API_CREATING_USER]="Создание пользователя XrayChecker..."
    [API_USER_CREATED]="Пользователь XrayChecker создан"
    [API_SUCCESS]="Подписка получена через API"
    [API_FAILED]="Ошибка получения подписки через API"
    [API_FALLBACK_MANUAL]="Ввести URL подписки вручную?"
    [API_ERROR]="Ошибка API"

    # SSL Сертификаты
    [SSL_TITLE]="НАСТРОЙКА SSL СЕРТИФИКАТА"
    [SSL_DOMAIN]="Домен"
    [SSL_EXISTING_FOUND]="Найдены существующие сертификаты"
    [SSL_CERTS_FOUND]="Найдены существующие сертификаты:"
    [SSL_CLOUDFLARE]="Cloudflare DNS-01"
    [SSL_CF_DESC]="Требуется API токен, поддержка wildcard"
    [SSL_ACME]="ACME HTTP-01 (standalone)"
    [SSL_ACME_DESC]="Порт 80 должен быть свободен"
    [SSL_GCORE]="Gcore DNS API"
    [SSL_GCORE_DESC]="Требуется API токен, поддержка wildcard"
    [SSL_USE_EXISTING]="Использовать существующий сертификат"
    [SSL_EXISTING]="Использовать существующий сертификат"
    [SSL_OBTAIN_NEW]="Получить новый сертификат"
    [SSL_SKIP]="Пропустить настройку SSL"
    [SSL_ENTER_CF_TOKEN]="Введите Cloudflare API Token:"
    [SSL_ENTER_GCORE_TOKEN]="Введите Gcore API Token:"
    [SSL_ENTER_EMAIL]="Введите email для Let's Encrypt:"
    [SSL_SELECT_CERT]="Выберите сертификат"
    [SSL_ENTER_CERT_NUM]="Введите номер:"
    [SSL_INSTALLING_CERTBOT]="Установка certbot..."
    [SSL_INSTALLING_CF_PLUGIN]="Установка плагина Cloudflare..."
    [SSL_INSTALLING_GCORE_PLUGIN]="Установка плагина Gcore..."
    [SSL_OBTAINING_CERT]="Получение сертификата"
    [SSL_CERT_OBTAINED]="Сертификат успешно получен"
    [SSL_CERT_FAILED]="Ошибка получения сертификата"
    [SSL_PORT80_BUSY]="Порт 80 занят, пытаемся освободить..."
    [SSL_RENEWAL_ENABLED]="Автопродление включено"

    # Binary Installation
    [BINARY_DETECTING_ARCH]="Определение архитектуры"
    [BINARY_DOWNLOADING]="Скачивание xray-checker"
    [BINARY_INSTALLED]="Бинарник установлен"
    [BINARY_INSTALLING]="Установка xray-checker (бинарник)..."
    [BINARY_CREATING_USER]="Создание системного пользователя"
    [BINARY_USER_EXISTS]="Пользователь уже существует"
    [BINARY_SERVICE_CREATED]="Systemd сервис создан"
    [BINARY_UPDATING]="Обновление xray-checker..."
    [BINARY_UPDATED]="Бинарник обновлён"
    [BINARY_UNINSTALLING]="Удаление бинарника..."
    [BINARY_UNINSTALLED]="Бинарник удалён"
    [ERROR_UNSUPPORTED_ARCH]="Неподдерживаемая архитектура"
    [ERROR_FETCH_RELEASE]="Ошибка получения информации о релизе"
    [ERROR_NO_BINARY]="Бинарник не найден для"
    [ERROR_DOWNLOAD_BINARY]="Ошибка скачивания бинарника"
    [ERROR_UNKNOWN_FORMAT]="Неизвестный формат архива"
    [ERROR_BINARY_NOT_FOUND]="Бинарник не найден в архиве"
)

# ══════════════════════════════════════════════════════════════════════════════
# УТИЛИТЫ
# ══════════════════════════════════════════════════════════════════════════════

# Очистка и нормализация ввода
sanitize_input() {
    local _val="$1"

    if command -v perl >/dev/null 2>&1; then
        _val=$(printf '%s' "$_val" | perl -CSD -MUnicode::Normalize -pe '
            $_ = NFKC($_);
            s/\p{C}//g;
            s/[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{206F}\x{FEFF}]//g;
            s/^\s+|\s+$//g;
        ' 2>/dev/null) || _val=$(printf '%s' "$1" | tr -cd '[:print:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    else
        _val=$(printf '%s' "$_val" | tr -cd '[:print:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi

    printf '%s' "$_val"
}

# Чтение ввода с поддержкой редактирования
reading() {
    local prompt="$1"
    local varname="$2"
    local value

    read -e -r -p "$prompt " value
    value=$(sanitize_input "$value")

    printf -v "$varname" '%s' "$value"
}

# Чтение обязательного поля
reading_required() {
    local prompt="$1"
    local varname="$2"
    local value=""

    while [ -z "$value" ]; do
        read -e -r -p "$prompt " value
        value=$(sanitize_input "$value")

        if [ -z "$value" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
        fi
    done

    printf -v "$varname" '%s' "$value"
}

# Чтение пароля (скрытый ввод)
reading_secret() {
    local prompt="$1"
    local varname="$2"
    local value

    read -e -r -s -p "$prompt " value
    echo
    value=$(sanitize_input "$value")

    printf -v "$varname" '%s' "$value"
}

# Чтение с значением по умолчанию
reading_default() {
    local prompt="$1"
    local varname="$2"
    local default="$3"
    local value

    read -e -r -p "$prompt [$default]: " value
    value=$(sanitize_input "$value")

    [ -z "$value" ] && value="$default"

    printf -v "$varname" '%s' "$value"
}

# Чтение URL
reading_url() {
    local prompt="$1"
    local varname="$2"
    local value=""

    while true; do
        read -e -r -p "$prompt " value
        value=$(sanitize_input "$value")

        if [ -z "$value" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
            continue
        fi

        if [[ "$value" =~ ^https?:// ]] || [[ "$value" =~ ^file:// ]] || [[ "$value" =~ ^folder:// ]]; then
            break
        else
            echo -e "${COLOR_RED}${LANG[INVALID_URL]}${COLOR_RESET}"
        fi
    done

    printf -v "$varname" '%s' "$value"
}

# Чтение числа
reading_number() {
    local prompt="$1"
    local varname="$2"
    local default="${3:-}"
    local value=""

    while true; do
        if [ -n "$default" ]; then
            read -e -r -p "$prompt [$default]: " value
        else
            read -e -r -p "$prompt: " value
        fi

        value=$(sanitize_input "$value")

        if [ -z "$value" ] && [ -n "$default" ]; then
            value="$default"
            break
        fi

        if [[ "$value" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${COLOR_RED}${LANG[INVALID_NUMBER]}${COLOR_RESET}"
        fi
    done

    printf -v "$varname" '%s' "$value"
}

# Чтение Yes/No
reading_yn() {
    local prompt="$1"
    local varname="$2"
    local default="${3:-n}"
    local value=""

    local hint="y/N"
    [[ "$default" == "y" ]] && hint="Y/n"

    while true; do
        read -e -r -p "$prompt ($hint): " value
        value=$(sanitize_input "$value")
        value=$(echo "$value" | tr '[:upper:]' '[:lower:]')

        [ -z "$value" ] && value="$default"

        case "$value" in
            y|yes|да|д) value="y"; break ;;
            n|no|нет|н) value="n"; break ;;
            *) echo -e "${COLOR_RED}${LANG[INVALID_YN]}${COLOR_RESET}" ;;
        esac
    done

    printf -v "$varname" '%s' "$value"
}

# Spinner для длительных операций
spinner() {
    local pid=$1
    local text=$2

    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local delay=0.1

    printf "${COLOR_GREEN}%s${COLOR_RESET}" "$text" >/dev/tty

    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf "\r${COLOR_GREEN}[%s] %s${COLOR_RESET}" "${spinstr:$i:1}" "$text" >/dev/tty
            sleep $delay
        done
    done

    printf "\r\033[K" >/dev/tty
}

# Вывод ошибки и выход
error_exit() {
    echo -e "${COLOR_RED}${LANG[ERROR]}: $1${COLOR_RESET}" >&2
    exit 1
}

# Вывод предупреждения
warning() {
    echo -e "${COLOR_YELLOW}${LANG[WARNING]}: $1${COLOR_RESET}"
}

# Вывод успеха
success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

# Вывод информации
info() {
    echo -e "${COLOR_CYAN}ℹ $1${COLOR_RESET}"
}

# Вывод ошибки и выход
error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}" >&2
    exit 1
}

# Очистка экрана
clear_screen() {
    clear 2>/dev/null || printf "\033c"
}

# Печать разделителя
print_separator() {
    local char="${1:-═}"
    local width="${2:-60}"
    printf "${COLOR_GRAY}"
    printf '%*s' "$width" '' | tr ' ' "$char"
    printf "${COLOR_RESET}\n"
}

# Печать заголовка в рамке
print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))

    echo ""
    printf "${COLOR_GREEN}${BOX_TL}"
    printf '%*s' "$width" '' | tr ' ' '-'
    printf "${BOX_TR}${COLOR_RESET}\n"

    printf "${COLOR_GREEN}${BOX_V}${COLOR_RESET}"
    printf '%*s' "$padding" ''
    printf "${COLOR_WHITE}${title}${COLOR_RESET}"
    printf '%*s' "$((width - padding - ${#title}))" ''
    printf "${COLOR_GREEN}${BOX_V}${COLOR_RESET}\n"

    printf "${COLOR_GREEN}${BOX_BL}"
    printf '%*s' "$width" '' | tr ' ' '-'
    printf "${BOX_BR}${COLOR_RESET}\n"
    echo ""
}

# Печать пункта меню
print_menu_item() {
    local num="$1"
    local text="$2"
    local hint="${3:-}"

    printf "  ${COLOR_YELLOW}%s.${COLOR_RESET} %s" "$num" "$text"
    [ -n "$hint" ] && printf " ${COLOR_GRAY}(%s)${COLOR_RESET}" "$hint"
    printf "\n"
}

# Получение IP сервера
get_server_ip() {
    curl -s -4 ifconfig.me 2>/dev/null || \
    curl -s -4 icanhazip.com 2>/dev/null || \
    curl -s -4 ipecho.net/plain 2>/dev/null || \
    hostname -I 2>/dev/null | awk '{print $1}' || \
    echo "YOUR_SERVER_IP"
}

# Генерация случайного пароля
generate_password() {
    local length="${1:-24}"
    openssl rand -base64 48 2>/dev/null | tr -dc 'a-zA-Z0-9!@#$%' | head -c "$length" || \
    cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%' | head -c "$length"
}

# Генерация имени пользователя
generate_username() {
    echo "xchecker_$(openssl rand -hex 4 2>/dev/null || cat /dev/urandom | tr -dc 'a-f0-9' | head -c 8)"
}

# ══════════════════════════════════════════════════════════════════════════════
# НАСТРОЙКА ЯЗЫКА
# ══════════════════════════════════════════════════════════════════════════════

set_language() {
    case "$1" in
        en|EN|english|English)
            for key in "${!LANG_EN[@]}"; do
                LANG[$key]="${LANG_EN[$key]}"
            done
            SELECTED_LANG="en"
            ;;
        ru|RU|russian|Russian|русский)
            for key in "${!LANG_RU[@]}"; do
                LANG[$key]="${LANG_RU[$key]}"
            done
            SELECTED_LANG="ru"
            ;;
        *)
            # По умолчанию английский
            for key in "${!LANG_EN[@]}"; do
                LANG[$key]="${LANG_EN[$key]}"
            done
            SELECTED_LANG="en"
            ;;
    esac
}

select_language() {
    clear_screen

    echo ""
    print_box_top 60
    print_box_line_text "${COLOR_WHITE}SELECT LANGUAGE / ВЫБЕРИТЕ ЯЗЫК${COLOR_RESET}" 60
    print_box_bottom 60
    echo ""
    echo -e "  ${COLOR_YELLOW}1.${COLOR_RESET} English"
    echo -e "  ${COLOR_YELLOW}2.${COLOR_RESET} Русский"
    echo -e "  ${COLOR_YELLOW}0.${COLOR_RESET} Exit / Выход"
    echo ""

    local choice
    read -r -p "  Select / Выберите [0-2]: " choice

    case "$choice" in
        0) clear_screen; exit 0 ;;
        1) set_language "en" ;;
        2) set_language "ru" ;;
        *) set_language "en" ;;
    esac

    # Сохранить выбор
    mkdir -p "$DIR_XRAY_CHECKER"
    echo "$SELECTED_LANG" > "$FILE_LANG"
}

load_language() {
    if [ -f "$FILE_LANG" ]; then
        local saved_lang
        saved_lang=$(cat "$FILE_LANG")
        set_language "$saved_lang"
    else
        set_language "en"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ПРОВЕРКИ СИСТЕМЫ
# ══════════════════════════════════════════════════════════════════════════════

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "${LANG[ERROR_ROOT]}"
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian)
                case "$VERSION_CODENAME" in
                    bullseye|bookworm) return 0 ;;
                esac
                ;;
            ubuntu)
                case "$VERSION_CODENAME" in
                    jammy|noble) return 0 ;;
                esac
                ;;
        esac
    fi

    error_exit "${LANG[ERROR_OS]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# УСТАНОВКА ПАКЕТОВ
# ══════════════════════════════════════════════════════════════════════════════

install_packages() {
    info "${LANG[INSTALLING_PACKAGES]}"

    apt-get update -y >/dev/null 2>&1 || error_exit "apt-get update failed"

    apt-get install -y \
        ca-certificates \
        curl \
        wget \
        jq \
        gnupg \
        lsb-release \
        >/dev/null 2>&1 || error_exit "Failed to install packages"

    success "${LANG[INSTALLING_PACKAGES]}"
}

install_docker() {
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        success "Docker already installed"
        return 0
    fi

    info "${LANG[INSTALLING_DOCKER]}"

    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh || error_exit "${LANG[ERROR_DOCKER]}"
    sh /tmp/get-docker.sh >/dev/null 2>&1 || error_exit "${LANG[ERROR_DOCKER]}"
    rm -f /tmp/get-docker.sh

    systemctl enable docker >/dev/null 2>&1
    systemctl start docker >/dev/null 2>&1

    success "${LANG[INSTALLING_DOCKER]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# REMNAWAVE API ИНТЕГРАЦИЯ
# ══════════════════════════════════════════════════════════════════════════════

# Константы для API
XRAY_CHECKER_USERNAME="XrayChecker"

# Извлечение cookie из nginx.conf (для eGames установки)
extract_egames_cookie() {
    local nginx_conf="/opt/remnawave/nginx.conf"
    
    if [ ! -f "$nginx_conf" ]; then
        return 1
    fi
    
    # Извлекаем строку с cookie из map блока
    local cookie_line
    cookie_line=$(grep -A 2 'map $http_cookie $auth_cookie' "$nginx_conf" 2>/dev/null | grep '~\*' | head -1)
    
    if [ -z "$cookie_line" ]; then
        return 1
    fi
    
    # Парсим имя и значение cookie: "~*aEmFnBcC=WbYWpixX" 1;
    EGAMES_COOKIE_NAME=$(echo "$cookie_line" | sed -n 's/.*~\*\([^=]*\)=.*/\1/p')
    EGAMES_COOKIE_VALUE=$(echo "$cookie_line" | sed -n 's/.*=\([^"]*\)".*/\1/p')
    
    if [ -n "$EGAMES_COOKIE_NAME" ] && [ -n "$EGAMES_COOKIE_VALUE" ]; then
        return 0
    fi
    
    return 1
}

# Проверка существования пользователя XrayChecker
check_xraychecker_user() {
    local panel_url="$1"
    local api_token="$2"
    local cookie_header="${3:-}"
    
    local response
    local http_code
    
    if [ -n "$cookie_header" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer ${api_token}" \
            -H "Cookie: ${cookie_header}" \
            "${panel_url}/api/users/by-username/${XRAY_CHECKER_USERNAME}" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer ${api_token}" \
            "${panel_url}/api/users/by-username/${XRAY_CHECKER_USERNAME}" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # Пользователь существует — извлекаем subscriptionUrl
        API_SUBSCRIPTION_URL=$(echo "$body" | jq -r '.response.subscriptionUrl // empty' 2>/dev/null)
        if [ -n "$API_SUBSCRIPTION_URL" ]; then
            return 0
        fi
    fi
    
    return 1
}

# Создание пользователя XrayChecker
create_xraychecker_user() {
    local panel_url="$1"
    local api_token="$2"
    local cookie_header="${3:-}"
    
    local payload='{
        "username": "'"${XRAY_CHECKER_USERNAME}"'",
        "expireAt": "2099-12-31T23:59:59.000Z",
        "trafficLimitBytes": 0,
        "trafficLimitStrategy": "NO_RESET",
        "status": "ACTIVE",
        "description": "Auto-created by xray-checker installer for monitoring"
    }'
    
    local response
    local http_code
    
    if [ -n "$cookie_header" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -X POST \
            -H "Authorization: Bearer ${api_token}" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${cookie_header}" \
            -d "$payload" \
            "${panel_url}/api/users" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" \
            -X POST \
            -H "Authorization: Bearer ${api_token}" \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "${panel_url}/api/users" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        API_SUBSCRIPTION_URL=$(echo "$body" | jq -r '.response.subscriptionUrl // empty' 2>/dev/null)
        if [ -n "$API_SUBSCRIPTION_URL" ]; then
            return 0
        fi
    fi
    
    # Сохраняем ошибку для отображения
    API_ERROR=$(echo "$body" | jq -r '.message // .error // "Unknown error"' 2>/dev/null)
    return 1
}

# Получение подписки через Remnawave API
get_subscription_via_api() {
    local panel_url="$1"
    local api_token="$2"
    local use_cookie="$3"
    
    local cookie_header=""
    
    # Если нужны cookie (eGames установка)
    if [ "$use_cookie" = "y" ]; then
        if [ -n "$EGAMES_COOKIE_NAME" ] && [ -n "$EGAMES_COOKIE_VALUE" ]; then
            cookie_header="${EGAMES_COOKIE_NAME}=${EGAMES_COOKIE_VALUE}"
        else
            # Запросить вручную
            echo ""
            echo -e "${COLOR_YELLOW}${LANG[API_COOKIE_INFO]}${COLOR_RESET}"
            echo -e "${COLOR_GRAY}${LANG[API_COOKIE_HINT]}${COLOR_RESET}"
            echo ""
            reading "${LANG[API_ENTER_COOKIE_NAME]}" MANUAL_COOKIE_NAME
            reading "${LANG[API_ENTER_COOKIE_VALUE]}" MANUAL_COOKIE_VALUE
            
            if [ -n "$MANUAL_COOKIE_NAME" ] && [ -n "$MANUAL_COOKIE_VALUE" ]; then
                cookie_header="${MANUAL_COOKIE_NAME}=${MANUAL_COOKIE_VALUE}"
            fi
        fi
    fi
    
    echo ""
    info "${LANG[API_CHECKING_USER]}"
    
    # Шаг 1: Проверить существует ли пользователь
    if check_xraychecker_user "$panel_url" "$api_token" "$cookie_header"; then
        success "${LANG[API_USER_FOUND]}"
        return 0
    fi
    
    # Шаг 2: Создать нового пользователя
    info "${LANG[API_CREATING_USER]}"
    
    if create_xraychecker_user "$panel_url" "$api_token" "$cookie_header"; then
        success "${LANG[API_USER_CREATED]}"
        return 0
    fi
    
    # Ошибка
    echo -e "${COLOR_RED}${LANG[API_ERROR]}: ${API_ERROR}${COLOR_RESET}"
    return 1
}

# Меню выбора источника подписки
choose_subscription_source() {
    clear_screen
    print_header "${LANG[SUB_MODE_TITLE]}"
    
    echo ""
    print_menu_item "1" "${LANG[SUB_MANUAL]}"
    print_menu_item "2" "${LANG[SUB_API]}"
    echo ""
    print_menu_item "0" "${LANG[BACK]}"
    echo ""
    
    local choice
    reading "${LANG[SELECT_OPTION]}:" choice
    
    case "$choice" in
        1)
            # Ручной ввод URL (с авто-добавлением https://)
            echo ""
            local sub_input=""
            while [ -z "$sub_input" ]; do
                reading "${LANG[ENTER_SUBSCRIPTION_URL]}" sub_input
                if [ -z "$sub_input" ]; then
                    echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
                fi
            done
            
            # Автоматически добавляем https:// если не указан протокол
            if [[ ! "$sub_input" =~ ^https?:// ]] && [[ ! "$sub_input" =~ ^file:// ]] && [[ ! "$sub_input" =~ ^folder:// ]]; then
                SUBSCRIPTION_URL="https://${sub_input}"
            else
                SUBSCRIPTION_URL="$sub_input"
            fi
            
            echo ""
            success "${LANG[SUBSCRIPTION_CONFIGURED]}"
            echo -e "${COLOR_GRAY}URL: ${SUBSCRIPTION_URL}${COLOR_RESET}"
            echo ""
            return 0
            ;;
        2)
            # Remnawave API
            setup_remnawave_api
            return $?
            ;;
        0)
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Настройка Remnawave API
setup_remnawave_api() {
    clear_screen
    print_header "${LANG[SUB_API]}"
    
    echo ""
    echo -e "${COLOR_WHITE}${LANG[API_DESCRIPTION]}${COLOR_RESET}"
    echo -e "${COLOR_CYAN}${LANG[API_USER_PREFIX]}: ${COLOR_YELLOW}${LANG[API_USERNAME]}${COLOR_RESET}"
    echo ""
    
    # Ввод URL панели (с авто-добавлением https://)
    local panel_input=""
    while [ -z "$panel_input" ]; do
        reading "${LANG[SUB_ENTER_PANEL_URL]}" panel_input
        if [ -z "$panel_input" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
        fi
    done
    
    # Автоматически добавляем https:// если не указан протокол
    if [[ ! "$panel_input" =~ ^https?:// ]]; then
        PANEL_URL="https://${panel_input}"
    else
        PANEL_URL="$panel_input"
    fi
    
    # Удалить trailing slash
    PANEL_URL="${PANEL_URL%/}"
    
    echo ""
    echo -e "${COLOR_GREEN}URL: ${COLOR_CYAN}${PANEL_URL}${COLOR_RESET}"
    echo ""
    
    # Инструкция получения API токена
    echo -e "${COLOR_YELLOW}${LANG[API_TOKEN_HINT_TITLE]}${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}${LANG[API_TOKEN_HINT_1]}${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}${LANG[API_TOKEN_HINT_2]}${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}${LANG[API_TOKEN_HINT_3]}${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}${LANG[API_TOKEN_HINT_4]}${COLOR_RESET}"
    echo ""
    
    # Ввод API токена с подтверждением
    local token_confirmed="n"
    while [ "$token_confirmed" != "y" ]; do
        reading_required "${LANG[SUB_ENTER_API_TOKEN]}" API_TOKEN
        
        echo ""
        echo -e "${COLOR_WHITE}${LANG[API_TOKEN_CONFIRM]}${COLOR_RESET}"
        echo -e "  ${COLOR_CYAN}${API_TOKEN:0:20}...${COLOR_RESET}"
        echo ""
        
        local confirm
        reading_yn "" confirm "y"
        token_confirmed="$confirm"
        
        if [ "$token_confirmed" != "y" ]; then
            echo ""
        fi
    done
    
    echo ""
    
    # Определить тип установки панели
    echo -e "${COLOR_CYAN}${LANG[API_INSTALL_TYPE]}${COLOR_RESET}"
    print_menu_item "1" "${LANG[API_INSTALL_OFFICIAL]}"
    print_menu_item "2" "${LANG[API_INSTALL_EGAMES]}"
    print_menu_item "0" "${LANG[BACK]}"
    echo ""

    local install_type
    reading "${LANG[SELECT_OPTION]}:" install_type
    
    [ "$install_type" = "0" ] && return 1

    local use_cookie="n"
    
    if [ "$install_type" = "2" ]; then
        use_cookie="y"
        
        # Попробовать автоматически извлечь cookie
        info "${LANG[API_EXTRACTING_COOKIE]}"
        if extract_egames_cookie; then
            success "Cookie found: ${EGAMES_COOKIE_NAME}=***"
        else
            warning "${LANG[API_COOKIE_NOT_FOUND]}"
        fi
    fi
    
    # Получить подписку
    if get_subscription_via_api "$PANEL_URL" "$API_TOKEN" "$use_cookie"; then
        SUBSCRIPTION_URL="$API_SUBSCRIPTION_URL"
        
        # Сохранить конфигурацию API для будущего использования
        save_api_config
        
        echo ""
        success "${LANG[API_SUCCESS]}"
        echo -e "  ${COLOR_WHITE}URL:${COLOR_RESET} ${COLOR_CYAN}${SUBSCRIPTION_URL}${COLOR_RESET}"
        echo ""
        
        read -r -p "${LANG[PRESS_ENTER]}"
        return 0
    else
        echo ""
        warning "${LANG[API_FAILED]}"
        echo ""
        
        # Предложить ввести вручную
        local fallback
        reading_yn "${LANG[API_FALLBACK_MANUAL]}" fallback "y"
        
        if [ "$fallback" = "y" ]; then
            reading_url "${LANG[ENTER_SUBSCRIPTION_URL]}" SUBSCRIPTION_URL
            return 0
        fi
        
        return 1
    fi
}

# Сохранение конфигурации API
save_api_config() {
    mkdir -p "$DIR_XRAY_CHECKER"
    
    cat > "$FILE_API_CONFIG" <<EOF
# Remnawave API Configuration
# Saved by xray-checker installer

PANEL_URL="${PANEL_URL}"
API_TOKEN="${API_TOKEN}"
SUBSCRIPTION_MODE="api"
XRAY_CHECKER_USERNAME="${XRAY_CHECKER_USERNAME}"
EOF
    
    chmod 600 "$FILE_API_CONFIG"
}

# ══════════════════════════════════════════════════════════════════════════════
# REVERSE PROXY DETECTION
# ══════════════════════════════════════════════════════════════════════════════

# Глобальные переменные для reverse proxy
DETECTED_PROXY="none"
DETECTED_PROXY_PATH=""
DETECTED_CERTS="none"
XCHECKER_DOMAIN=""

detect_reverse_proxy() {
    DETECTED_PROXY="none"
    DETECTED_PROXY_PATH=""
    DETECTED_CERTS="none"

    # 1. Проверка eGames установки (nginx.conf в корне /opt/remnawave/)
    if [ -f "/opt/remnawave/nginx.conf" ] && [ ! -d "/opt/remnawave/nginx" ]; then
        DETECTED_PROXY="egames_nginx"
        DETECTED_PROXY_PATH="/opt/remnawave/nginx.conf"
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 2. Проверка официальной установки Remnawave — Caddy
    if [ -f "/opt/remnawave/caddy/Caddyfile" ]; then
        DETECTED_PROXY="remnawave_caddy"
        DETECTED_PROXY_PATH="/opt/remnawave/caddy/Caddyfile"
        return 0
    fi

    # 3. Проверка официальной установки Remnawave — Nginx
    if [ -f "/opt/remnawave/nginx/nginx.conf" ]; then
        DETECTED_PROXY="remnawave_nginx"
        DETECTED_PROXY_PATH="/opt/remnawave/nginx/nginx.conf"
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 4. Проверка системного Nginx
    if systemctl is-active --quiet nginx 2>/dev/null; then
        DETECTED_PROXY="system_nginx"
        DETECTED_PROXY_PATH="/etc/nginx/sites-available/"
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 5. Проверка Docker nginx
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qiE "nginx|remnawave-nginx"; then
        DETECTED_PROXY="docker_nginx"
        return 0
    fi

    # 6. Проверка системного Caddy
    if systemctl is-active --quiet caddy 2>/dev/null; then
        DETECTED_PROXY="system_caddy"
        DETECTED_PROXY_PATH="/etc/caddy/Caddyfile"
        return 0
    fi

    # 7. Проверка Docker caddy
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qiE "caddy|remnawave-caddy"; then
        DETECTED_PROXY="docker_caddy"
        return 0
    fi

    return 1
}

get_proxy_display_name() {
    case "$DETECTED_PROXY" in
        egames_nginx)      echo "eGames Nginx (Remnawave)" ;;
        remnawave_caddy)   echo "Remnawave Caddy" ;;
        remnawave_nginx)   echo "Remnawave Nginx" ;;
        system_nginx)      echo "System Nginx" ;;
        docker_nginx)      echo "Docker Nginx" ;;
        system_caddy)      echo "System Caddy" ;;
        docker_caddy)      echo "Docker Caddy" ;;
        *)                 echo "None" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# SSL СЕРТИФИКАТЫ
# ══════════════════════════════════════════════════════════════════════════════

# Глобальные переменные для SSL
SSL_CERT_PATH=""
SSL_KEY_PATH=""
SSL_DOMAIN=""

# Установка certbot если нет
install_certbot() {
    if command -v certbot &>/dev/null; then
        return 0
    fi
    
    info "${LANG[SSL_INSTALLING_CERTBOT]}"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y certbot >/dev/null 2>&1
    
    return $?
}

# Установка плагина Cloudflare для certbot
install_certbot_cloudflare() {
    if [ -f "/usr/lib/python3/dist-packages/certbot_dns_cloudflare/__init__.py" ] || \
       pip3 show certbot-dns-cloudflare &>/dev/null 2>&1; then
        return 0
    fi
    
    info "${LANG[SSL_INSTALLING_CF_PLUGIN]}"
    apt-get install -y python3-certbot-dns-cloudflare >/dev/null 2>&1 || \
        pip3 install certbot-dns-cloudflare >/dev/null 2>&1
    
    return $?
}

# Получение сертификата через Cloudflare DNS-01
get_cert_cloudflare() {
    local domain="$1"
    local email="$2"
    local cf_token="$3"
    
    install_certbot || return 1
    install_certbot_cloudflare || return 1
    
    # Создать файл с credentials
    mkdir -p ~/.secrets/certbot
    cat > ~/.secrets/certbot/cloudflare.ini <<EOF
dns_cloudflare_api_token = ${cf_token}
EOF
    chmod 600 ~/.secrets/certbot/cloudflare.ini
    
    info "${LANG[SSL_OBTAINING_CERT]} (Cloudflare DNS-01)..."
    
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 30 \
        -d "$domain" \
        --email "$email" \
        --agree-tos \
        --non-interactive \
        --quiet
    
    if [ $? -eq 0 ] && [ -d "/etc/letsencrypt/live/${domain}" ]; then
        SSL_CERT_PATH="/etc/letsencrypt/live/${domain}/fullchain.pem"
        SSL_KEY_PATH="/etc/letsencrypt/live/${domain}/privkey.pem"
        SSL_DOMAIN="$domain"
        success "${LANG[SSL_CERT_OBTAINED]}"
        return 0
    fi
    
    return 1
}

# Получение сертификата через ACME HTTP-01 (standalone)
get_cert_acme_standalone() {
    local domain="$1"
    local email="$2"
    
    install_certbot || return 1
    
    # Проверить, свободен ли порт 80
    if ss -tlnp | grep -q ':80 '; then
        warning "${LANG[SSL_PORT80_BUSY]}"
        
        # Попробовать остановить nginx временно
        if systemctl is-active --quiet nginx; then
            systemctl stop nginx
            local nginx_was_running=1
        fi
    fi
    
    info "${LANG[SSL_OBTAINING_CERT]} (ACME HTTP-01)..."
    
    # Временно открыть порт 80 в UFW
    ufw allow 80/tcp >/dev/null 2>&1
    
    certbot certonly \
        --standalone \
        --preferred-challenges http \
        -d "$domain" \
        --email "$email" \
        --agree-tos \
        --non-interactive \
        --quiet
    
    local result=$?
    
    # Закрыть порт 80
    ufw delete allow 80/tcp >/dev/null 2>&1
    
    # Восстановить nginx если был запущен
    [ "${nginx_was_running:-0}" = "1" ] && systemctl start nginx
    
    if [ $result -eq 0 ] && [ -d "/etc/letsencrypt/live/${domain}" ]; then
        SSL_CERT_PATH="/etc/letsencrypt/live/${domain}/fullchain.pem"
        SSL_KEY_PATH="/etc/letsencrypt/live/${domain}/privkey.pem"
        SSL_DOMAIN="$domain"
        success "${LANG[SSL_CERT_OBTAINED]}"
        return 0
    fi
    
    return 1
}

# Получение сертификата через Gcore DNS API
get_cert_gcore() {
    local domain="$1"
    local email="$2"
    local gcore_token="$3"
    
    install_certbot || return 1
    
    # Установить плагин Gcore
    if ! pip3 show certbot-dns-gcore &>/dev/null 2>&1; then
        info "${LANG[SSL_INSTALLING_GCORE_PLUGIN]}"
        pip3 install certbot-dns-gcore >/dev/null 2>&1 || {
            warning "Failed to install certbot-dns-gcore plugin"
            return 1
        }
    fi
    
    # Создать файл с credentials
    mkdir -p ~/.secrets/certbot
    cat > ~/.secrets/certbot/gcore.ini <<EOF
dns_gcore_apitoken = ${gcore_token}
EOF
    chmod 600 ~/.secrets/certbot/gcore.ini
    
    info "${LANG[SSL_OBTAINING_CERT]} (Gcore DNS)..."
    
    certbot certonly \
        --authenticator dns-gcore \
        --dns-gcore-credentials ~/.secrets/certbot/gcore.ini \
        --dns-gcore-propagation-seconds 30 \
        -d "$domain" \
        --email "$email" \
        --agree-tos \
        --non-interactive \
        --quiet
    
    if [ $? -eq 0 ] && [ -d "/etc/letsencrypt/live/${domain}" ]; then
        SSL_CERT_PATH="/etc/letsencrypt/live/${domain}/fullchain.pem"
        SSL_KEY_PATH="/etc/letsencrypt/live/${domain}/privkey.pem"
        SSL_DOMAIN="$domain"
        success "${LANG[SSL_CERT_OBTAINED]}"
        return 0
    fi
    
    return 1
}

# Использование существующих сертификатов
use_existing_certs() {
    local domain="$1"
    
    # Поиск сертификатов в стандартных местах
    local cert_dirs=(
        "/etc/letsencrypt/live/${domain}"
        "/etc/letsencrypt/live"
        "/opt/xray-checker/certs"
        "/etc/ssl/certs"
    )
    
    # Если указан конкретный домен, проверить его сертификаты
    if [ -n "$domain" ] && [ -d "/etc/letsencrypt/live/${domain}" ]; then
        if [ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ] && \
           [ -f "/etc/letsencrypt/live/${domain}/privkey.pem" ]; then
            SSL_CERT_PATH="/etc/letsencrypt/live/${domain}/fullchain.pem"
            SSL_KEY_PATH="/etc/letsencrypt/live/${domain}/privkey.pem"
            SSL_DOMAIN="$domain"
            return 0
        fi
    fi
    
    return 1
}

# Список доступных сертификатов в /etc/letsencrypt/live/
list_available_certs() {
    if [ ! -d "/etc/letsencrypt/live" ]; then
        return 1
    fi
    
    local certs=()
    for dir in /etc/letsencrypt/live/*/; do
        local name=$(basename "$dir")
        if [ "$name" != "README" ] && [ -f "${dir}fullchain.pem" ]; then
            certs+=("$name")
        fi
    done
    
    if [ ${#certs[@]} -eq 0 ]; then
        return 1
    fi
    
    printf '%s\n' "${certs[@]}"
    return 0
}

# Меню выбора метода получения SSL сертификата
choose_ssl_method() {
    local domain="$1"
    
    clear_screen
    print_header "${LANG[SSL_TITLE]}"
    
    echo -e "  ${COLOR_WHITE}${LANG[SSL_DOMAIN]}:${COLOR_RESET} ${COLOR_CYAN}${domain}${COLOR_RESET}"
    echo ""
    
    # Проверить существующие сертификаты
    local existing_certs
    existing_certs=$(list_available_certs 2>/dev/null)
    
    if [ -n "$existing_certs" ]; then
        echo -e "  ${COLOR_GREEN}${LANG[SSL_EXISTING_FOUND]}:${COLOR_RESET}"
        echo "$existing_certs" | while read -r cert; do
            echo -e "    ${COLOR_GRAY}• ${cert}${COLOR_RESET}"
        done
        echo ""
    fi
    
    print_menu_item "1" "${LANG[SSL_CLOUDFLARE]}" "${LANG[SSL_CF_DESC]}"
    print_menu_item "2" "${LANG[SSL_ACME]}" "${LANG[SSL_ACME_DESC]}"
    print_menu_item "3" "${LANG[SSL_GCORE]}" "${LANG[SSL_GCORE_DESC]}"
    
    if [ -n "$existing_certs" ]; then
        print_menu_item "4" "${LANG[SSL_USE_EXISTING]}"
    fi
    
    print_menu_item "0" "${LANG[SSL_SKIP]}"
    echo ""
    
    local choice
    reading "${LANG[SELECT_OPTION]}:" choice
    
    case "$choice" in
        1)
            # Cloudflare DNS-01
            echo ""
            reading_required "${LANG[SSL_ENTER_CF_TOKEN]}" CF_TOKEN
            reading_required "${LANG[SSL_ENTER_EMAIL]}" CERT_EMAIL
            
            get_cert_cloudflare "$domain" "$CERT_EMAIL" "$CF_TOKEN"
            return $?
            ;;
        2)
            # ACME HTTP-01 (standalone)
            echo ""
            reading_required "${LANG[SSL_ENTER_EMAIL]}" CERT_EMAIL
            
            get_cert_acme_standalone "$domain" "$CERT_EMAIL"
            return $?
            ;;
        3)
            # Gcore DNS
            echo ""
            reading_required "${LANG[SSL_ENTER_GCORE_TOKEN]}" GCORE_TOKEN
            reading_required "${LANG[SSL_ENTER_EMAIL]}" CERT_EMAIL
            
            get_cert_gcore "$domain" "$CERT_EMAIL" "$GCORE_TOKEN"
            return $?
            ;;
        4)
            # Использовать существующие
            if [ -n "$existing_certs" ]; then
                echo ""
                echo -e "${COLOR_WHITE}${LANG[SSL_SELECT_CERT]}:${COLOR_RESET}"
                echo "$existing_certs" | nl -w2 -s'. '
                echo ""
                
                reading "${LANG[SSL_ENTER_CERT_NUM]}" cert_num
                local selected_cert
                selected_cert=$(echo "$existing_certs" | sed -n "${cert_num}p")
                
                if [ -n "$selected_cert" ]; then
                    use_existing_certs "$selected_cert"
                    return $?
                fi
            fi
            return 1
            ;;
        0|*)
            # Пропустить SSL
            return 1
            ;;
    esac
}

# Настройка автообновления сертификатов
setup_cert_renewal() {
    # Certbot автоматически создаёт cron/systemd timer
    # Проверим, что он работает
    if systemctl is-enabled certbot.timer &>/dev/null; then
        success "${LANG[SSL_RENEWAL_ENABLED]}"
        return 0
    fi
    
    # Попробуем включить
    systemctl enable certbot.timer &>/dev/null
    systemctl start certbot.timer &>/dev/null
    
    return 0
}

# Генерация Nginx server block для xray-checker
generate_nginx_block() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local cert_path="${3:-/etc/letsencrypt/live/${domain}}"

    cat <<EOF

# ═══════════════════════════════════════════════════════════════
# xray-checker (added by xchecker installer)
# ═══════════════════════════════════════════════════════════════
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${domain};

    ssl_certificate ${cert_path}/fullchain.pem;
    ssl_certificate_key ${cert_path}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
}

# Генерация Caddy block для xray-checker
generate_caddy_block() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"

    cat <<EOF

# xray-checker (added by xchecker installer)
${domain} {
    reverse_proxy 127.0.0.1:${port}
}
EOF
}

# Добавить конфигурацию в существующий nginx
add_to_nginx() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local nginx_conf="$DETECTED_PROXY_PATH"
    local cert_path=""

    # Проверка наличия существующих сертификатов
    if [ -d "/etc/letsencrypt/live" ]; then
        local existing_certs
        existing_certs=$(list_existing_certs 2>/dev/null)
        if [ -n "$existing_certs" ]; then
            # Есть существующие сертификаты
            echo ""
            info "${LANG[SSL_CERTS_FOUND]}"
            echo "$existing_certs"
            echo ""
            echo -e "${COLOR_WHITE}1. ${LANG[SSL_EXISTING]}${COLOR_RESET}"
            echo -e "${COLOR_WHITE}2. ${LANG[SSL_OBTAIN_NEW]}${COLOR_RESET}"
            echo -e "${COLOR_WHITE}0. ${LANG[BACK]}${COLOR_RESET}"
            echo ""
            local ssl_choice
            reading "${LANG[SELECT_OPTION]}:" ssl_choice

            case "$ssl_choice" in
                0) return 1 ;;
                1)
                    select_existing_cert "$domain"
                    cert_path="$SELECTED_CERT_PATH"
                    ;;
                *)
                    choose_ssl_method "$domain"
                    cert_path="/etc/letsencrypt/live/${domain}"
                    ;;
            esac
        else
            # Нет сертификатов — получить новые
            choose_ssl_method "$domain"
            cert_path="/etc/letsencrypt/live/${domain}"
        fi
    else
        # Нет папки letsencrypt — получить новые
        choose_ssl_method "$domain"
        cert_path="/etc/letsencrypt/live/${domain}"
    fi

    # Проверить что сертификаты есть
    if [ -z "$cert_path" ] || [ ! -d "$cert_path" ]; then
        error "SSL certificates not found at: ${cert_path}"
        return 1
    fi

    # Создать backup
    cp "$nginx_conf" "${nginx_conf}.backup.$(date +%Y%m%d%H%M%S)"

    # Добавить блок
    local nginx_block
    nginx_block=$(generate_nginx_block "$domain" "$port" "$cert_path")

    # Для eGames nginx — добавляем перед последней закрывающей скобкой или в конец
    if [ "$DETECTED_PROXY" = "egames_nginx" ]; then
        echo "$nginx_block" >> "$nginx_conf"
    else
        # Для обычного nginx — создаём в sites-available
        local site_file="/etc/nginx/sites-available/xray-checker"
        echo "$nginx_block" > "$site_file"
        ln -sf "$site_file" "/etc/nginx/sites-enabled/xray-checker"
    fi

    # Проверка конфигурации и перезагрузка
    if [ "$DETECTED_PROXY" = "egames_nginx" ] || [ "$DETECTED_PROXY" = "docker_nginx" ]; then
        # Docker nginx
        local container_name
        container_name=$(docker ps --format '{{.Names}}' | grep -iE "nginx|remnawave-nginx" | head -1)
        if [ -n "$container_name" ]; then
            docker exec "$container_name" nginx -t 2>/dev/null && \
            docker exec "$container_name" nginx -s reload 2>/dev/null
        fi
    else
        # System nginx
        nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null
    fi

    return 0
}

# Добавить конфигурацию в существующий Caddy
add_to_caddy() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local caddyfile="$DETECTED_PROXY_PATH"

    # Создать backup
    cp "$caddyfile" "${caddyfile}.backup.$(date +%Y%m%d%H%M%S)"

    # Добавить блок
    generate_caddy_block "$domain" "$port" >> "$caddyfile"

    # Перезагрузка
    if [ "$DETECTED_PROXY" = "docker_caddy" ] || [ "$DETECTED_PROXY" = "remnawave_caddy" ]; then
        local container_name
        container_name=$(docker ps --format '{{.Names}}' | grep -iE "caddy|remnawave-caddy" | head -1)
        if [ -n "$container_name" ]; then
            docker exec "$container_name" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null
        fi
    else
        systemctl reload caddy 2>/dev/null
    fi

    return 0
}

# Установка Caddy в Docker
install_caddy_docker() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"

    info "Installing Caddy in Docker..."

    mkdir -p /opt/caddy
    cd /opt/caddy

    # Создать Caddyfile
    cat > Caddyfile <<EOF
# Caddy configuration for xray-checker
${domain} {
    reverse_proxy xray-checker:2112
}
EOF

    # Создать docker-compose
    cat > docker-compose.yml <<EOF
services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - ${DOCKER_NETWORK}

volumes:
  caddy_data:
  caddy_config:

networks:
  ${DOCKER_NETWORK}:
    external: true
EOF

    docker compose up -d

    DETECTED_PROXY="docker_caddy"
    DETECTED_PROXY_PATH="/opt/caddy/Caddyfile"

    success "Caddy installed"
}

# Установка Nginx в Docker
install_nginx_docker() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local cert_path=""

    info "Installing Nginx in Docker..."

    # Получение SSL сертификата
    echo ""
    info "${LANG[SSL_TITLE]}"
    
    if [ -d "/etc/letsencrypt/live" ]; then
        local existing_certs
        existing_certs=$(list_existing_certs 2>/dev/null)
        if [ -n "$existing_certs" ]; then
            echo ""
            info "${LANG[SSL_CERTS_FOUND]}"
            echo "$existing_certs"
            echo ""
            echo -e "${COLOR_WHITE}1. ${LANG[SSL_EXISTING]}${COLOR_RESET}"
            echo -e "${COLOR_WHITE}2. ${LANG[SSL_OBTAIN_NEW]}${COLOR_RESET}"
            echo -e "${COLOR_WHITE}0. ${LANG[SSL_SKIP]}${COLOR_RESET}"
            echo ""
            local ssl_choice
            reading "${LANG[SELECT_OPTION]}:" ssl_choice

            case "$ssl_choice" in
                0) cert_path="" ;;
                1)
                    select_existing_cert "$domain"
                    cert_path="$SELECTED_CERT_PATH"
                    ;;
                *)
                    choose_ssl_method "$domain"
                    cert_path="/etc/letsencrypt/live/${domain}"
                    ;;
            esac
        else
            choose_ssl_method "$domain"
            cert_path="/etc/letsencrypt/live/${domain}"
        fi
    else
        choose_ssl_method "$domain"
        cert_path="/etc/letsencrypt/live/${domain}"
    fi

    # Проверить что сертификаты есть
    if [ -z "$cert_path" ] || [ ! -d "$cert_path" ]; then
        warning "SSL certificates not obtained. Installing HTTP-only nginx."
        cert_path=""
    fi

    mkdir -p /opt/nginx/conf.d
    mkdir -p /opt/nginx/certs
    cd /opt/nginx

    # Создать nginx.conf
    cat > nginx.conf <<EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    # Создать server block
    if [ -n "$cert_path" ] && [ -d "$cert_path" ]; then
        # HTTPS конфигурация
        cat > conf.d/xray-checker.conf <<EOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${domain};

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://xray-checker:2112;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
        # Копировать сертификаты
        cp "${cert_path}/fullchain.pem" /opt/nginx/certs/
        cp "${cert_path}/privkey.pem" /opt/nginx/certs/
    else
        # HTTP-only конфигурация
        cat > conf.d/xray-checker.conf <<EOF
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass http://xray-checker:2112;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    fi

    # Создать docker-compose
    cat > docker-compose.yml <<EOF
services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./certs:/etc/nginx/certs:ro
    networks:
      - ${DOCKER_NETWORK}

networks:
  ${DOCKER_NETWORK}:
    external: true
EOF

    docker compose up -d

    DETECTED_PROXY="docker_nginx"
    DETECTED_PROXY_PATH="/opt/nginx/conf.d/xray-checker.conf"

    if [ -n "$cert_path" ]; then
        success "Nginx installed with HTTPS"
    else
        success "Nginx installed (HTTP only)"
        warning "SSL certificates need to be configured manually"
    fi
}

# Меню настройки Reverse Proxy
setup_reverse_proxy() {
    clear_screen
    print_header "${LANG[PROXY_TITLE]}"

    # Определение окружения
    info "Detecting environment..."
    detect_reverse_proxy

    local proxy_name
    proxy_name=$(get_proxy_display_name)

    echo ""
    if [ "$DETECTED_PROXY" != "none" ]; then
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[PROXY_DETECTED]}: ${COLOR_CYAN}${proxy_name}${COLOR_RESET}"
        [ -n "$DETECTED_PROXY_PATH" ] && echo -e "    ${COLOR_GRAY}Path: ${DETECTED_PROXY_PATH}${COLOR_RESET}"
        [ "$DETECTED_CERTS" = "letsencrypt" ] && echo -e "    ${COLOR_GRAY}SSL: Let's Encrypt certificates found${COLOR_RESET}"
    else
        echo -e "  ${COLOR_YELLOW}!${COLOR_RESET} ${LANG[PROXY_NONE]}"
    fi
    echo ""

    # Варианты в зависимости от обнаруженного proxy
    if [ "$DETECTED_PROXY" != "none" ]; then
        print_menu_item "1" "${LANG[PROXY_USE_EXISTING]} ${proxy_name}"
        print_menu_item "2" "${LANG[PROXY_SKIP]}"
        print_menu_item "0" "${LANG[BACK]}"
        echo ""

        local choice
        reading "${LANG[SELECT_OPTION]}:" choice

        case "$choice" in
            1)
                # Использовать существующий proxy
                reading_required "${LANG[PROXY_ENTER_DOMAIN]}" XCHECKER_DOMAIN

                case "$DETECTED_PROXY" in
                    *nginx*) add_to_nginx "$XCHECKER_DOMAIN" "$DEFAULT_PORT" ;;
                    *caddy*) add_to_caddy "$XCHECKER_DOMAIN" "$DEFAULT_PORT" ;;
                esac

                success "Reverse proxy configured for ${XCHECKER_DOMAIN}"
                ;;
            2|0)
                XCHECKER_DOMAIN=""
                return 0
                ;;
        esac
    else
        print_menu_item "1" "${LANG[PROXY_CADDY]}" "${LANG[RECOMMENDED]}"
        print_menu_item "2" "${LANG[PROXY_NGINX]}"
        print_menu_item "3" "${LANG[PROXY_SKIP]}"
        print_menu_item "0" "${LANG[BACK]}"
        echo ""

        local choice
        reading "${LANG[SELECT_OPTION]}:" choice

        case "$choice" in
            1)
                reading_required "${LANG[PROXY_ENTER_DOMAIN]}" XCHECKER_DOMAIN
                install_caddy_docker "$XCHECKER_DOMAIN" "$DEFAULT_PORT"
                ;;
            2)
                reading_required "${LANG[PROXY_ENTER_DOMAIN]}" XCHECKER_DOMAIN
                install_nginx_docker "$XCHECKER_DOMAIN" "$DEFAULT_PORT"
                ;;
            3|0)
                XCHECKER_DOMAIN=""
                return 0
                ;;
        esac
    fi

    read -r -p "${LANG[PRESS_ENTER]}"
}

# Показать информацию о доступе
show_access_info() {
    local port="${1:-$DEFAULT_PORT}"
    local ip
    ip=$(get_server_ip)

    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[WEB_INTERFACE]}:${COLOR_RESET}"

    if [ -n "$XCHECKER_DOMAIN" ]; then
        echo -e "    ${COLOR_CYAN}https://${XCHECKER_DOMAIN}${COLOR_RESET}"
    fi
    echo -e "    ${COLOR_CYAN}http://${ip}:${port}${COLOR_RESET} ${COLOR_GRAY}(direct)${COLOR_RESET}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# ГЕНЕРАЦИЯ КОНФИГУРАЦИИ
# ══════════════════════════════════════════════════════════════════════════════

generate_credentials() {
    METRICS_USERNAME=$(generate_username)
    METRICS_PASSWORD=$(generate_password 24)
    METRICS_PROTECTED="true"
}

generate_env_file() {
    local sub_url="${1:-}"
    local port="${2:-$DEFAULT_PORT}"
    local protected="${3:-true}"
    local username="${4:-$METRICS_USERNAME}"
    local password="${5:-$METRICS_PASSWORD}"
    local public_dashboard="${6:-false}"

    cat > "$FILE_ENV" <<EOF
### SUBSCRIPTION ###
SUBSCRIPTION_URL=${sub_url}
SUBSCRIPTION_UPDATE=true
SUBSCRIPTION_UPDATE_INTERVAL=300

### PROXY CHECK ###
PROXY_CHECK_INTERVAL=300
PROXY_CHECK_METHOD=status
PROXY_IP_CHECK_URL=https://api.ipify.org?format=text
PROXY_STATUS_CHECK_URL=http://cp.cloudflare.com/generate_204
PROXY_DOWNLOAD_URL=https://proof.ovh.net/files/1Mb.dat
PROXY_DOWNLOAD_TIMEOUT=60
PROXY_DOWNLOAD_MIN_SIZE=51200
PROXY_TIMEOUT=30
PROXY_RESOLVE_DOMAINS=false
SIMULATE_LATENCY=true

### XRAY ###
XRAY_START_PORT=10000
XRAY_LOG_LEVEL=none

### METRICS & AUTH ###
METRICS_HOST=0.0.0.0
METRICS_PORT=${port}
METRICS_PROTECTED=${protected}
METRICS_USERNAME=${username}
METRICS_PASSWORD=${password}
METRICS_INSTANCE=
METRICS_PUSH_URL=
# METRICS_BASE_PATH=

### WEB UI ###
WEB_SHOW_DETAILS=false
WEB_PUBLIC=${public_dashboard}

### LOGGING ###
LOG_LEVEL=info
RUN_ONCE=false
EOF

    chmod 600 "$FILE_ENV"
}

generate_docker_compose() {
    local port="${1:-$DEFAULT_PORT}"
    local bind_host="${2:-0.0.0.0}"  # По умолчанию открыт наружу

    cat > "$FILE_COMPOSE" <<EOF
services:
  xray-checker:
    image: ${DOCKER_IMAGE}
    container_name: ${DOCKER_CONTAINER}
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "${bind_host}:\${METRICS_PORT:-${port}}:2112"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:2112/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

networks:
  default:
    external: true
    name: ${DOCKER_NETWORK}
EOF
}

# ══════════════════════════════════════════════════════════════════════════════
# BINARY INSTALLATION (systemd)
# ══════════════════════════════════════════════════════════════════════════════

BINARY_PATH="/usr/local/bin/xray-checker"
SYSTEMD_SERVICE="/etc/systemd/system/xray-checker.service"
BINARY_USER="xray-checker"
GITHUB_REPO="kutovoys/xray-checker"

# Определение архитектуры системы
get_system_arch() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armv7)
            echo "armv7"
            ;;
        i386|i686)
            echo "386"
            ;;
        *)
            error "${LANG[ERROR_UNSUPPORTED_ARCH]}: $arch"
            return 1
            ;;
    esac
}

# Получить URL последней версии бинарника
get_latest_binary_url() {
    local arch="$1"
    local os="linux"
    
    # Получить информацию о последнем релизе
    local release_info
    release_info=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}/releases/latest")
    
    if [ -z "$release_info" ]; then
        error "${LANG[ERROR_FETCH_RELEASE]}"
        return 1
    fi
    
    # Извлечь версию
    LATEST_VERSION=$(echo "$release_info" | grep -oP '"tag_name":\s*"\K[^"]+')
    
    # Найти URL для нашей архитектуры (ищем .tar.gz или просто бинарник)
    local download_url
    download_url=$(echo "$release_info" | grep -oP '"browser_download_url":\s*"\K[^"]+' | \
        grep -E "${os}.*${arch}" | grep -E '\.(tar\.gz|zip)$' | head -1)
    
    if [ -z "$download_url" ]; then
        # Попробовать найти без архива
        download_url=$(echo "$release_info" | grep -oP '"browser_download_url":\s*"\K[^"]+' | \
            grep -E "${os}.*${arch}" | head -1)
    fi
    
    if [ -z "$download_url" ]; then
        error "${LANG[ERROR_NO_BINARY]}: ${os}-${arch}"
        return 1
    fi
    
    echo "$download_url"
}

# Скачать и установить бинарник
download_and_install_binary() {
    local arch
    arch=$(get_system_arch) || return 1
    
    info "${LANG[BINARY_DETECTING_ARCH]}: $arch"
    
    local download_url
    download_url=$(get_latest_binary_url "$arch") || return 1
    
    info "${LANG[BINARY_DOWNLOADING]} ${LATEST_VERSION}..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local tmp_file="${tmp_dir}/xray-checker-download"
    
    # Скачать файл
    if ! curl -sL "$download_url" -o "$tmp_file"; then
        rm -rf "$tmp_dir"
        error "${LANG[ERROR_DOWNLOAD_BINARY]}"
        return 1
    fi
    
    # Определить тип файла и распаковать если нужно
    local binary_file
    if file "$tmp_file" | grep -q "gzip"; then
        # tar.gz архив
        tar -xzf "$tmp_file" -C "$tmp_dir" 2>/dev/null
        binary_file=$(find "$tmp_dir" -type f -name "xray-checker*" ! -name "*.tar.gz" | head -1)
        [ -z "$binary_file" ] && binary_file=$(find "$tmp_dir" -type f -executable | head -1)
    elif file "$tmp_file" | grep -q "Zip"; then
        # zip архив
        unzip -q "$tmp_file" -d "$tmp_dir" 2>/dev/null
        binary_file=$(find "$tmp_dir" -type f -name "xray-checker*" ! -name "*.zip" | head -1)
    elif file "$tmp_file" | grep -qE "executable|ELF"; then
        # Уже бинарник
        binary_file="$tmp_file"
    else
        rm -rf "$tmp_dir"
        error "${LANG[ERROR_UNKNOWN_FORMAT]}"
        return 1
    fi
    
    if [ -z "$binary_file" ] || [ ! -f "$binary_file" ]; then
        rm -rf "$tmp_dir"
        error "${LANG[ERROR_BINARY_NOT_FOUND]}"
        return 1
    fi
    
    # Остановить сервис если запущен
    systemctl stop xray-checker 2>/dev/null || true
    
    # Установить бинарник
    cp "$binary_file" "$BINARY_PATH"
    chmod +x "$BINARY_PATH"
    
    # Очистка
    rm -rf "$tmp_dir"
    
    success "${LANG[BINARY_INSTALLED]}: ${LATEST_VERSION}"
    return 0
}

# Создать системного пользователя
create_system_user() {
    if id "$BINARY_USER" &>/dev/null; then
        info "${LANG[BINARY_USER_EXISTS]}: $BINARY_USER"
        return 0
    fi
    
    info "${LANG[BINARY_CREATING_USER]}: $BINARY_USER"
    useradd -r -s /bin/false -d /nonexistent "$BINARY_USER"
    
    return 0
}

# Сгенерировать systemd service файл
generate_systemd_service() {
    local env_file="${DIR_XRAY_CHECKER}.env"
    
    cat > "$SYSTEMD_SERVICE" <<EOF
[Unit]
Description=Xray Checker - Proxy Monitoring Tool
Documentation=https://github.com/${GITHUB_REPO}
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${BINARY_USER}
Group=${BINARY_USER}

# Environment file
EnvironmentFile=${env_file}

# Working directory
WorkingDirectory=${DIR_XRAY_CHECKER}

# Main process
ExecStart=${BINARY_PATH}

# Restart policy
Restart=always
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
ReadWritePaths=${DIR_XRAY_CHECKER}

# Capabilities (для xray-core может понадобиться сеть)
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_RAW
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW

# Limits
LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

    info "${LANG[BINARY_SERVICE_CREATED]}"
}

# Полная установка binary
install_binary_method() {
    local sub_url="$1"
    local port="${2:-$DEFAULT_PORT}"
    local protected="${3:-false}"
    local username="${4:-}"
    local password="${5:-}"
    local web_public="${6:-false}"

    info "${LANG[BINARY_INSTALLING]}"

    # 1. Скачать и установить бинарник
    download_and_install_binary || return 1

    # 2. Создать пользователя
    create_system_user

    # 3. Создать директорию конфигурации
    mkdir -p "$DIR_XRAY_CHECKER"
    
    # 4. Сгенерировать .env файл
    generate_env_file "$sub_url" "$port" "$protected" "$username" "$password" "$web_public"
    
    # 5. Установить права на директорию
    chown -R "${BINARY_USER}:${BINARY_USER}" "$DIR_XRAY_CHECKER"
    chmod 700 "$DIR_XRAY_CHECKER"
    chmod 600 "${DIR_XRAY_CHECKER}.env"

    # 6. Создать systemd service
    generate_systemd_service

    # 7. Перезагрузить systemd и включить сервис
    systemctl daemon-reload
    systemctl enable xray-checker >/dev/null 2>&1

    # 8. Запустить сервис
    info "${LANG[STARTING_SERVICE]}"
    systemctl start xray-checker

    # Записать метод установки
    echo "binary" > "$FILE_METHOD"

    return 0
}

# Обновить binary до последней версии
update_binary() {
    info "${LANG[BINARY_UPDATING]}"
    
    # Получить текущую версию
    local current_version=""
    if [ -x "$BINARY_PATH" ]; then
        current_version=$("$BINARY_PATH" --version 2>/dev/null | grep -oP 'v?\d+\.\d+\.\d+' | head -1)
    fi
    
    # Скачать новую версию
    download_and_install_binary || return 1
    
    # Перезапустить сервис
    systemctl restart xray-checker
    
    if [ -n "$current_version" ]; then
        info "${LANG[BINARY_UPDATED]}: ${current_version} → ${LATEST_VERSION}"
    else
        info "${LANG[BINARY_UPDATED]}: ${LATEST_VERSION}"
    fi
    
    return 0
}

# Удалить binary установку
uninstall_binary() {
    info "${LANG[BINARY_UNINSTALLING]}"
    
    # Остановить и отключить сервис
    systemctl stop xray-checker 2>/dev/null || true
    systemctl disable xray-checker 2>/dev/null || true
    
    # Удалить файлы
    rm -f "$SYSTEMD_SERVICE"
    rm -f "$BINARY_PATH"
    
    # Удалить пользователя
    userdel "$BINARY_USER" 2>/dev/null || true
    
    # Перезагрузить systemd
    systemctl daemon-reload
    
    success "${LANG[BINARY_UNINSTALLED]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# УСТАНОВКА
# ══════════════════════════════════════════════════════════════════════════════

quick_install() {
    clear_screen
    print_header "${LANG[MENU_QUICK_INSTALL]}"

    echo -e "${COLOR_WHITE}${LANG[QUICK_INSTALL_DESC]}${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GRAY}${LANG[ENTER_0_TO_BACK]}${COLOR_RESET}"
    echo ""

    # 1. Запрос URL подписки (с авто-добавлением https://)
    local sub_input=""
    while [ -z "$sub_input" ]; do
        reading "${LANG[ENTER_SUBSCRIPTION_URL]}" sub_input
        if [ -z "$sub_input" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
        fi
    done
    
    # Проверка на выход
    if [ "$sub_input" = "0" ]; then
        return
    fi
    
    # Автоматически добавляем https:// если не указан протокол
    local sub_url
    if [[ ! "$sub_input" =~ ^https?:// ]] && [[ ! "$sub_input" =~ ^file:// ]] && [[ ! "$sub_input" =~ ^folder:// ]]; then
        sub_url="https://${sub_input}"
    else
        sub_url="$sub_input"
    fi

    # 2. Способ доступа
    echo ""
    echo -e "${COLOR_CYAN}${LANG[ACCESS_METHOD_TITLE]}${COLOR_RESET}"
    echo ""
    print_menu_item "1" "${LANG[ACCESS_DIRECT_IP]}"
    echo -e "      ${COLOR_GRAY}${LANG[ACCESS_DIRECT_IP_DESC]}${COLOR_RESET}"
    print_menu_item "2" "${LANG[ACCESS_REVERSE_PROXY]}"
    echo -e "      ${COLOR_GRAY}${LANG[ACCESS_REVERSE_PROXY_DESC]}${COLOR_RESET}"
    print_menu_item "0" "${LANG[BACK]}"
    echo ""

    local access_method
    reading "${LANG[SELECT_OPTION]}:" access_method
    
    [ "$access_method" = "0" ] && return

    local bind_host="0.0.0.0"
    local setup_proxy="n"
    
    if [ "$access_method" = "2" ]; then
        bind_host="127.0.0.1"
        setup_proxy="y"
    fi

    echo ""
    info "${LANG[CHECKING_SYSTEM]}"

    # Проверки и установка
    check_os
    install_packages
    install_docker

    # Создание Docker-сети если нет
    docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1 || \
        docker network create "$DOCKER_NETWORK" >/dev/null 2>&1

    # Создание директории
    mkdir -p "$DIR_XRAY_CHECKER"
    cd "$DIR_XRAY_CHECKER"

    # Генерация учётных данных
    generate_credentials

    # Генерация конфигурации
    info "${LANG[CREATING_CONFIG]}"
    generate_env_file "$sub_url" "$DEFAULT_PORT" "true" "$METRICS_USERNAME" "$METRICS_PASSWORD" "false"
    generate_docker_compose "$DEFAULT_PORT" "$bind_host"

    # Сохранение метода установки
    echo "docker" > "$FILE_METHOD"

    # Запуск
    info "${LANG[STARTING_SERVICE]}"
    docker compose pull >/dev/null 2>&1
    docker compose up -d >/dev/null 2>&1

    # Проверка здоровья
    sleep 3
    info "${LANG[CHECKING_HEALTH]}"
    if curl -sf "http://127.0.0.1:${DEFAULT_PORT}/health" >/dev/null 2>&1; then
        success "${LANG[CHECKING_HEALTH]}"
    else
        warning "${LANG[ERROR_HEALTH]}"
    fi

    # Настройка reverse proxy если выбрано
    if [ "$setup_proxy" = "y" ]; then
        setup_reverse_proxy
    fi

    # Установка alias
    install_alias

    # Показать результат
    show_credentials
    show_install_success "$DEFAULT_PORT"

    read -r -p "${LANG[PRESS_ENTER]}"
}

custom_install() {
    clear_screen
    print_header "${LANG[MENU_CUSTOM_INSTALL]}"

    echo -e "${COLOR_WHITE}${LANG[CUSTOM_INSTALL_DESC]}${COLOR_RESET}"
    echo ""

    # 1. Метод установки
    echo -e "${COLOR_CYAN}${LANG[CHOOSE_INSTALL_METHOD]}${COLOR_RESET}"
    print_menu_item "1" "${LANG[INSTALL_DOCKER]}" "${LANG[RECOMMENDED]}"
    print_menu_item "2" "${LANG[INSTALL_BINARY]}"
    print_menu_item "0" "${LANG[BACK]}"
    echo ""

    local install_method
    reading "${LANG[SELECT_OPTION]}:" install_method
    
    [ "$install_method" = "0" ] && return

    # 2. Источник подписки (ручной ввод или API)
    echo ""
    echo -e "${COLOR_CYAN}${LANG[SUB_MODE_TITLE]}${COLOR_RESET}"
    print_menu_item "1" "${LANG[SUB_MANUAL]}"
    print_menu_item "2" "${LANG[SUB_API]}"
    print_menu_item "0" "${LANG[BACK]}"
    echo ""

    local sub_source
    reading "${LANG[SELECT_OPTION]}:" sub_source
    
    [ "$sub_source" = "0" ] && return

    local sub_url=""

    case "$sub_source" in
        2)
            # Remnawave API
            if setup_remnawave_api; then
                sub_url="$SUBSCRIPTION_URL"
            else
                return 1
            fi
            ;;
        1|*)
            # Ручной ввод
            echo ""
            reading_url "${LANG[ENTER_SUBSCRIPTION_URL]}" sub_url
            ;;
    esac

    # 3. Порт
    echo ""
    local port
    reading_number "${LANG[ENTER_PORT]}" port "$DEFAULT_PORT"

    # 4. Basic Auth
    echo ""
    local enable_auth
    reading_yn "${LANG[ENABLE_AUTH]}" enable_auth "y"

    local protected="false"
    local username=""
    local password=""

    if [ "$enable_auth" = "y" ]; then
        protected="true"
        generate_credentials
        username="$METRICS_USERNAME"
        password="$METRICS_PASSWORD"
    fi

    # 5. Публичный дашборд
    echo ""
    local public_dashboard
    reading_yn "${LANG[ENABLE_PUBLIC_DASHBOARD]}" public_dashboard "n"

    local web_public="false"
    [ "$public_dashboard" = "y" ] && web_public="true"

    # 6. Reverse Proxy
    echo ""
    local setup_proxy
    reading_yn "Setup reverse proxy (domain + SSL)?" setup_proxy "n"

    echo ""
    info "${LANG[CHECKING_SYSTEM]}"

    # Установка
    check_os
    install_packages

    case "$install_method" in
        1|docker)
            install_docker

            docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1 || \
                docker network create "$DOCKER_NETWORK" >/dev/null 2>&1

            mkdir -p "$DIR_XRAY_CHECKER"
            cd "$DIR_XRAY_CHECKER"

            info "${LANG[CREATING_CONFIG]}"
            generate_env_file "$sub_url" "$port" "$protected" "$username" "$password" "$web_public"
            generate_docker_compose "$port"

            echo "docker" > "$FILE_METHOD"

            info "${LANG[STARTING_SERVICE]}"
            docker compose pull >/dev/null 2>&1
            docker compose up -d >/dev/null 2>&1
            ;;
        2|binary)
            install_binary_method "$sub_url" "$port" "$protected" "$username" "$password" "$web_public"
            ;;
    esac

    # Проверка здоровья
    sleep 3
    info "${LANG[CHECKING_HEALTH]}"
    if curl -sf "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
        success "${LANG[CHECKING_HEALTH]}"
    else
        warning "${LANG[ERROR_HEALTH]}"
    fi

    # Настройка reverse proxy если выбрано
    if [ "$setup_proxy" = "y" ]; then
        setup_reverse_proxy
    fi

    # Установка alias
    install_alias

    # Показать результат
    if [ "$enable_auth" = "y" ]; then
        show_credentials
    fi
    show_install_success "$port"

    read -r -p "${LANG[PRESS_ENTER]}"
}

show_credentials() {
    echo ""
    print_box_top 60
    print_box_line_text "${COLOR_WHITE}🔐 ${LANG[CREDENTIALS_TITLE]}${COLOR_RESET}" 60
    print_box_bottom 60
    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[USERNAME]}:${COLOR_RESET}  ${COLOR_YELLOW}${METRICS_USERNAME}${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}${LANG[PASSWORD]}:${COLOR_RESET}  ${COLOR_YELLOW}${METRICS_PASSWORD}${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_GRAY}${LANG[CREDENTIALS_HINT]}${COLOR_RESET}"
    echo -e "  ${COLOR_GRAY}${LANG[CREDENTIALS_FILE]}: ${FILE_ENV}${COLOR_RESET}"
    echo ""
}

show_install_success() {
    local port="${1:-$DEFAULT_PORT}"
    local ip
    ip=$(get_server_ip)

    echo ""
    print_box_top 60
    print_box_line_text "${COLOR_WHITE}✅ ${LANG[INSTALL_COMPLETE]}${COLOR_RESET}" 60
    print_box_bottom 60
    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[WEB_INTERFACE]}:${COLOR_RESET}"
    if [ -n "$XCHECKER_DOMAIN" ]; then
        echo -e "    ${COLOR_CYAN}https://${XCHECKER_DOMAIN}${COLOR_RESET} ${COLOR_GREEN}(secure)${COLOR_RESET}"
    fi
    echo -e "    ${COLOR_CYAN}http://${ip}:${port}${COLOR_RESET} ${COLOR_GRAY}(direct)${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[METRICS_ENDPOINT]}:${COLOR_RESET}"
    if [ -n "$XCHECKER_DOMAIN" ]; then
        echo -e "    ${COLOR_CYAN}https://${XCHECKER_DOMAIN}/metrics${COLOR_RESET}"
    fi
    echo -e "    ${COLOR_CYAN}http://${ip}:${port}/metrics${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[HEALTH_ENDPOINT]}:${COLOR_RESET}"
    echo -e "    ${COLOR_CYAN}http://${ip}:${port}/health${COLOR_RESET}"
    echo ""
    
    # Предупреждение о HTTP если нет домена
    if [ -z "$XCHECKER_DOMAIN" ]; then
        echo -e "  ${COLOR_YELLOW}⚠️  ${LANG[HTTP_WARNING]}${COLOR_RESET}"
        echo -e "  ${COLOR_GRAY}${LANG[HTTPS_RECOMMENDED]}${COLOR_RESET}"
        echo ""
    fi
    
    echo -e "  ${COLOR_WHITE}${LANG[RERUN_CMD]}:${COLOR_RESET}"
    echo -e "    ${COLOR_YELLOW}xchecker${COLOR_RESET}"
    echo ""
}

install_alias() {
    local alias_cmd="alias xchecker='bash <(curl -Ls ${SCRIPT_URL})'"
    local profile_files=("/root/.bashrc" "/root/.bash_profile")

    for profile in "${profile_files[@]}"; do
        if [ -f "$profile" ]; then
            if ! grep -q "alias xchecker" "$profile" 2>/dev/null; then
                echo "" >> "$profile"
                echo "# xray-checker installer" >> "$profile"
                echo "$alias_cmd" >> "$profile"
            fi
        fi
    done

    # Создать прямую ссылку
    cat > /usr/local/bin/xchecker <<EOF
#!/bin/bash
bash <(curl -Ls ${SCRIPT_URL})
EOF
    chmod +x /usr/local/bin/xchecker

    cat > /usr/local/bin/xray_checker_install <<EOF
#!/bin/bash
bash <(curl -Ls ${SCRIPT_URL})
EOF
    chmod +x /usr/local/bin/xray_checker_install
}

# ══════════════════════════════════════════════════════════════════════════════
# УПРАВЛЕНИЕ СЕРВИСОМ
# ══════════════════════════════════════════════════════════════════════════════

service_menu() {
    while true; do
        clear_screen
        print_header "${LANG[MANAGE_TITLE]}"

        # Статус
        local status_text="${COLOR_RED}${LANG[SERVICE_STOPPED]}${COLOR_RESET}"
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${DOCKER_CONTAINER}$"; then
            status_text="${COLOR_GREEN}${LANG[SERVICE_RUNNING]}${COLOR_RESET}"
        fi

        echo -e "  ${COLOR_WHITE}Status:${COLOR_RESET} ${status_text}"
        echo ""

        print_menu_item "1" "${LANG[SERVICE_START]}"
        print_menu_item "2" "${LANG[SERVICE_STOP]}"
        print_menu_item "3" "${LANG[SERVICE_RESTART]}"
        print_menu_item "4" "${LANG[SERVICE_LOGS]}"
        print_menu_item "5" "${LANG[SERVICE_UPDATE]}"
        print_menu_item "6" "${LANG[SERVICE_EDIT_ENV]}"
        print_menu_item "7" "${LANG[PROXY_TITLE]}"
        echo ""
        print_menu_item "0" "${LANG[BACK]}"
        echo ""

        local choice
        reading "${LANG[SELECT_OPTION]}:" choice

        case "$choice" in
            1) service_start ;;
            2) service_stop ;;
            3) service_restart ;;
            4) service_logs ;;
            5) service_update ;;
            6) service_edit_env ;;
            7) setup_reverse_proxy ;;
            0) return ;;
            *) ;;
        esac
    done
}

service_start() {
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            cd "$DIR_XRAY_CHECKER" 2>/dev/null || return
            docker compose up -d
            ;;
        binary)
            systemctl start xray-checker
            ;;
        *)
            warning "Unknown installation method"
            return
            ;;
    esac
    sleep 2
    success "${LANG[SERVICE_RUNNING]}"
    read -r -p "${LANG[PRESS_ENTER]}"
}

service_stop() {
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            cd "$DIR_XRAY_CHECKER" 2>/dev/null || return
            docker compose down
            ;;
        binary)
            systemctl stop xray-checker
            ;;
        *)
            warning "Unknown installation method"
            return
            ;;
    esac
    success "${LANG[SERVICE_STOPPED]}"
    read -r -p "${LANG[PRESS_ENTER]}"
}

service_restart() {
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            cd "$DIR_XRAY_CHECKER" 2>/dev/null || return
            docker compose restart
            ;;
        binary)
            systemctl restart xray-checker
            ;;
        *)
            warning "Unknown installation method"
            return
            ;;
    esac
    sleep 2
    success "${LANG[SERVICE_RUNNING]}"
    read -r -p "${LANG[PRESS_ENTER]}"
}

service_logs() {
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            cd "$DIR_XRAY_CHECKER" 2>/dev/null || return
            docker compose logs -f --tail=100
            ;;
        binary)
            journalctl -u xray-checker -f -n 100
            ;;
        *)
            warning "Unknown installation method"
            read -r -p "${LANG[PRESS_ENTER]}"
            ;;
    esac
}

service_update() {
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            cd "$DIR_XRAY_CHECKER" 2>/dev/null || return
            info "Pulling latest image..."
            docker compose pull
            docker compose up -d
            success "Container updated"
            ;;
        binary)
            update_binary
            ;;
        *)
            warning "Unknown installation method"
            ;;
    esac
    read -r -p "${LANG[PRESS_ENTER]}"
}

service_edit_env() {
    if [ -f "$FILE_ENV" ]; then
        ${EDITOR:-nano} "$FILE_ENV"
        echo ""
        local restart
        reading_yn "Restart service to apply changes?" restart "y"
        [ "$restart" = "y" ] && service_restart
    else
        warning "Config file not found: $FILE_ENV"
        read -r -p "${LANG[PRESS_ENTER]}"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ОБНОВЛЕНИЕ СКРИПТА
# ══════════════════════════════════════════════════════════════════════════════

update_script() {
    clear_screen
    print_header "${LANG[MENU_UPDATE_SCRIPT]}"

    info "${LANG[UPDATE_CHECKING]}"

    local remote_version
    remote_version=$(curl -sf "$SCRIPT_URL" 2>/dev/null | grep -m1 'SCRIPT_VERSION=' | sed -E 's/.*SCRIPT_VERSION="([^"]+)".*/\1/')

    if [ -z "$remote_version" ]; then
        warning "Failed to check for updates"
        read -r -p "${LANG[PRESS_ENTER]}"
        return
    fi

    echo ""
    echo -e "  ${COLOR_WHITE}${LANG[UPDATE_CURRENT]}:${COLOR_RESET} ${SCRIPT_VERSION}"
    echo -e "  ${COLOR_WHITE}${LANG[UPDATE_AVAILABLE]}:${COLOR_RESET} ${remote_version}"
    echo ""

    if [ "$SCRIPT_VERSION" = "$remote_version" ]; then
        success "${LANG[UPDATE_LATEST]}"
        read -r -p "${LANG[PRESS_ENTER]}"
        return
    fi

    local confirm
    reading_yn "${LANG[UPDATE_CONFIRM]}" confirm "y"

    if [ "$confirm" = "y" ]; then
        curl -fsSL "$SCRIPT_URL" -o /usr/local/bin/xchecker.tmp
        mv /usr/local/bin/xchecker.tmp /usr/local/bin/xchecker
        chmod +x /usr/local/bin/xchecker

        success "${LANG[UPDATE_SUCCESS]}"
        echo -e "${COLOR_YELLOW}${LANG[UPDATE_RESTART]}${COLOR_RESET}"
        exit 0
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# УДАЛЕНИЕ
# ══════════════════════════════════════════════════════════════════════════════

uninstall() {
    clear_screen
    print_header "${LANG[UNINSTALL_TITLE]}"

    local confirm
    reading_yn "${LANG[UNINSTALL_CONFIRM]}" confirm "n"

    if [ "$confirm" != "y" ]; then
        return
    fi

    echo ""

    # Определить метод установки
    local method=""
    [ -f "$FILE_METHOD" ] && method=$(cat "$FILE_METHOD")

    case "$method" in
        docker)
            # Остановка и удаление контейнера
            if [ -f "$FILE_COMPOSE" ]; then
                cd "$DIR_XRAY_CHECKER"
                docker compose down -v 2>/dev/null
            fi

            # Удаление образа
            docker rmi "$DOCKER_IMAGE" 2>/dev/null
            ;;
        binary)
            # Удаление binary установки
            uninstall_binary
            ;;
        *)
            # На всякий случай пробуем оба способа
            if [ -f "$FILE_COMPOSE" ]; then
                cd "$DIR_XRAY_CHECKER"
                docker compose down -v 2>/dev/null
                docker rmi "$DOCKER_IMAGE" 2>/dev/null
            fi
            if systemctl is-active --quiet xray-checker 2>/dev/null; then
                uninstall_binary
            fi
            ;;
    esac

    # Удаление директории
    rm -rf "$DIR_XRAY_CHECKER"

    # Удаление alias из bashrc
    sed -i '/xray-checker installer/d' /root/.bashrc 2>/dev/null
    sed -i '/alias xchecker/d' /root/.bashrc 2>/dev/null

    # Удаление команд
    rm -f /usr/local/bin/xchecker
    rm -f /usr/local/bin/xray_checker_install

    success "${LANG[UNINSTALL_COMPLETE]}"
    read -r -p "${LANG[PRESS_ENTER]}"
}

# ══════════════════════════════════════════════════════════════════════════════
# ГЛАВНОЕ МЕНЮ
# ══════════════════════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        clear_screen

        echo ""
        print_box_top 60
        print_box_empty 60
        print_box_line_text "${COLOR_WHITE}▀▄▀ █▀█ ▄▀█ █▄█ ▄▄ █▀▀ █░█ █▀▀ █▀▀ █▄▀ █▀▀ █▀█${COLOR_RESET}" 60
        print_box_line_text "${COLOR_WHITE}█░█ █▀▄ █▀█ ░█░ ░░ █▄▄ █▀█ ██▄ █▄▄ █░█ ██▄ █▀▄${COLOR_RESET}" 60
        print_box_empty 60
        print_box_line_text "${COLOR_GRAY}${LANG[VERSION]}: ${SCRIPT_VERSION}${COLOR_RESET}" 60
        print_box_empty 60
        print_box_bottom 60
        echo ""

        print_menu_item "1" "🚀 ${LANG[MENU_QUICK_INSTALL]}" "${LANG[RECOMMENDED]}"
        print_menu_item "2" "⚙️  ${LANG[MENU_CUSTOM_INSTALL]}"
        print_menu_item "3" "📊 ${LANG[MENU_MANAGE]}"
        print_menu_item "4" "🔄 ${LANG[MENU_UPDATE_SCRIPT]}"
        print_menu_item "5" "🗑️  ${LANG[MENU_UNINSTALL]}"
        echo ""
        print_menu_item "0" "${LANG[EXIT]}"
        echo ""

        local choice
        reading "${LANG[SELECT_OPTION]}:" choice

        case "$choice" in
            1) quick_install ;;
            2) custom_install ;;
            3) service_menu ;;
            4) update_script ;;
            5) uninstall ;;
            0) clear_screen; exit 0 ;;
            *) ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# ТОЧКА ВХОДА
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Проверка root
    check_root

    # Загрузить сохранённый язык или выбрать
    if [ -f "$FILE_LANG" ]; then
        load_language
    else
        select_language
    fi

    # Главное меню
    main_menu
}

# Запуск
main "$@"
