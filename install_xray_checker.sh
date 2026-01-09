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

# Отключаем bracket paste mode глобально (предотвращает задваивание при вставке)
printf '\e[?2004l' 2>/dev/null
# Также через bind если доступен
bind 'set enable-bracketed-paste off' 2>/dev/null

# Отключаем автозавершение при ошибках (интерактивный скрипт)
# set -e  # НЕ используем - вызывает проблемы с проверочными командами

# Принудительная установка UTF-8 локали для корректного отображения Unicode символов
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# ══════════════════════════════════════════════════════════════════════════════
# ВЕРСИЯ И КОНСТАНТЫ
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_VERSION="0.0.3-alpha"
SCRIPT_NAME="install_xray_checker.sh"
SCRIPT_URL="https://raw.githubusercontent.com/UnderGut/xray-checker-installer/main/install_xray_checker.sh"

# Директории
DIR_XRAY_CHECKER="/opt/xray-checker/"
DIR_INSTALLER_CONFIG="/etc/xray-checker/"
DIR_CERTS="${DIR_XRAY_CHECKER}certs/"

# Файлы конфигурации
FILE_ENV="${DIR_XRAY_CHECKER}.env"
FILE_COMPOSE="${DIR_XRAY_CHECKER}docker-compose.yml"
FILE_NGINX_CONF="${DIR_XRAY_CHECKER}nginx.conf"
FILE_INSTALLER_CONF="${DIR_INSTALLER_CONFIG}installer.conf"

# Docker
DOCKER_IMAGE="kutovoys/xray-checker:latest"
DOCKER_CONTAINER="xray-checker"
DOCKER_NETWORK="xray-checker-network"

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
    [INVALID_URL_FORMAT]="Invalid URL. Use https://, file:// or folder://"
    [INVALID_NUMBER]="Please enter a valid number"
    [INVALID_YN]="Please enter y or n"
    [CHECKING_URL]="Checking URL"
    [URL_OK]="URL is accessible"
    [URL_UNREACHABLE]="URL unreachable"
    [URL_ERROR]="URL error"
    [FILE_NOT_FOUND]="File not found"
    [FILE_OK]="File exists"
    [FOLDER_NOT_FOUND]="Folder not found"
    [FOLDER_OK]="Folder exists"

    # Main Menu
    [MENU_QUICK_INSTALL]="Quick Install"
    [MENU_CUSTOM_INSTALL]="Custom Install"
    [MENU_MANAGE]="Manage Service"
    [MENU_UPDATE_SCRIPT]="Update Script"
    [MENU_UNINSTALL]="Uninstall"
    [MENU_LANGUAGE]="Language"

    # Installation
    [INSTALL_TITLE]="INSTALLATION"
    [QUICK_INSTALL_DESC]="URL, file:// or folder://"
    [CUSTOM_INSTALL_DESC]="Advanced settings: port, auth, reverse proxy"
    [ENTER_SUBSCRIPTION]="Subscription:"
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
    [SERVICE_NOT_RUNNING]="Service is not running. Start it first."
    [SERVICE_NOT_INSTALLED]="Service is not installed"
    [CHECKER_VERSION]="xray-checker"
    [NOT_INSTALLED]="not installed"

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
    [PROXY_CADDY]="Install Caddy (auto SSL)"
    [PROXY_NGINX]="Install Nginx"
    [PROXY_USE_EXISTING]="Use existing"
    [PROXY_ADD_TO_EXISTING]="Add domain to"
    [PROXY_ENTER_DOMAIN]="Enter domain:"
    [DETECTING]="Detecting environment"
    [DOMAIN_CHECKING]="Checking domain DNS..."
    [DOMAIN_OK]="Domain points to this server"
    [DOMAIN_MISMATCH]="Domain points to different IP"
    [DOMAIN_NOT_RESOLVED]="Domain could not be resolved. Create A-record pointing to server IP"
    [DOMAIN_CLOUDFLARE]="Domain is proxied through Cloudflare"
    [DOMAIN_CLOUDFLARE_HINT]="Use Cloudflare DNS-01 for SSL certificate"
    [DOMAIN_SERVER_IP]="Server IP"
    [DOMAIN_DNS_IP]="Domain DNS"
    [DOMAIN_CONFIRM]="Continue with this domain?"
    [DOMAIN_CHANGE]="Enter different domain"
    [DOMAIN_BACK]="Go back"
    [DOMAIN_ALREADY_EXISTS]="Domain already configured in nginx"

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
    [API_COOKIE_INPUT_MODE]="How do you want to enter cookie data?"
    [API_COOKIE_MODE_URL]="Enter authorization URL from panel"
    [API_COOKIE_MODE_NGINX]="Paste nginx config block with cookie"
    [API_ENTER_AUTH_URL]="Enter authorization URL from panel:"
    [API_AUTH_URL_HINT]="URL format: https://domain/auth/login?xxx=yyy"
    [API_AUTH_URL_EXAMPLE]="Example: https://panel.example.com/auth/login?aEmFnBcC=WbYWpixX"
    [API_AUTH_URL_INVALID]="Invalid URL format. Must contain ?name=value"
    [API_AUTH_URL_PARSED]="Cookie extracted from URL"
    [API_NGINX_BLOCK_HINT]="Paste nginx config block containing 'map \$http_cookie' (press Enter twice to finish):"
    [API_NGINX_BLOCK_EXAMPLE]="Example: map \$http_cookie \$auth_cookie { default 0; \"~*aEmFnBcC=WbYWpixX\" 1; }"
    [API_NGINX_BLOCK_PARSED]="Cookie extracted from nginx config"
    [API_NGINX_BLOCK_INVALID]="Could not extract cookie from nginx block"
    [API_CHECKING_USER]="Checking XrayChecker user..."
    [API_USER_FOUND]="User XrayChecker already exists in panel"
    [API_USER_FOUND_HINT]="Using existing subscription. Squads not modified."
    [API_USER_FOUND_CHOICE]="User XrayChecker already exists. What to do?"
    [API_USER_USE_EXISTING]="Use existing user"
    [API_USER_RECREATE]="Delete and create new (will assign squads)"
    [API_USER_DELETING]="Deleting existing user..."
    [API_USER_DELETED]="User deleted"
    [API_CREATING_USER]="Creating XrayChecker user..."
    [API_USER_CREATED]="User XrayChecker created"
    [API_GETTING_SQUADS]="Getting Internal Squads..."
    [API_SQUADS_FOUND]="Squads found"
    [API_NO_SQUADS]="No Internal Squads found. User will be created without squads."
    [API_SQUADS_SELECT_MODE]="Assign squads to XrayChecker user:"
    [API_SQUADS_ALL]="Add all squads"
    [API_SQUADS_SELECT]="Select specific squads"
    [API_SQUADS_NONE]="No squads (skip)"
    [API_SQUADS_LIST]="Available squads:"
    [API_SQUADS_ENTER_NUMBERS]="Enter squad numbers separated by space (e.g. 1 3 5):"
    [API_SQUADS_SELECTED]="Selected squads"
    [API_SQUADS_HINT]="You can manage squads later in Remnawave panel"
    [API_SUCCESS]="Subscription obtained via API"
    [API_FAILED]="Failed to get subscription via API"
    [API_FALLBACK_MANUAL]="Enter subscription URL manually?"
    [API_ERROR]="API Error"

    # Reverse Proxy errors
    [PROXY_ALREADY_CONFIGURED]="Reverse proxy is already configured for xray-checker"
    [PROXY_ALREADY_HINT]="To add another domain, edit nginx.conf manually or reinstall"

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
    [SSL_WILDCARD_FOUND]="Wildcard certificate found"
    [SSL_WILDCARD_AUTO]="Using wildcard certificate automatically"
    [SSL_ENTER_CF_TOKEN]="Enter Cloudflare API Token:"
    [SSL_ENTER_GCORE_TOKEN]="Enter Gcore API Token:"
    [SSL_ENTER_EMAIL]="Enter email:"
    [SSL_EMAIL_HINT]="Used for expiry reminders, not spam"
    [SSL_INVALID_EMAIL]="Invalid email format"
    [SSL_VALIDATING_CF]="Validating Cloudflare API token..."
    [SSL_CF_VALID]="Cloudflare API token is valid"
    [SSL_CF_INVALID]="Invalid Cloudflare API token"
    [SSL_CF_RETRY]="Please enter valid token"
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
    [INVALID_URL_FORMAT]="Неверный URL. Используйте https://, file:// или folder://"
    [INVALID_NUMBER]="Введите корректное число"
    [INVALID_YN]="Введите y или n"
    [CHECKING_URL]="Проверка URL"
    [URL_OK]="URL доступен"
    [URL_UNREACHABLE]="URL недоступен"
    [URL_ERROR]="Ошибка URL"
    [FILE_NOT_FOUND]="Файл не найден"
    [FILE_OK]="Файл найден"
    [FOLDER_NOT_FOUND]="Папка не найдена"
    [FOLDER_OK]="Папка найдена"

    # Главное меню
    [MENU_QUICK_INSTALL]="Быстрая установка"
    [MENU_CUSTOM_INSTALL]="Расширенная установка"
    [MENU_MANAGE]="Управление сервисом"
    [MENU_UPDATE_SCRIPT]="Обновить скрипт"
    [MENU_UNINSTALL]="Удаление"
    [MENU_LANGUAGE]="Язык"

    # Установка
    [INSTALL_TITLE]="УСТАНОВКА"
    [QUICK_INSTALL_DESC]="URL, file:// или folder://"
    [CUSTOM_INSTALL_DESC]="Расширенные настройки: порт, авторизация, reverse proxy"
    [ENTER_SUBSCRIPTION]="Подписка:"
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
    [SERVICE_NOT_RUNNING]="Сервис не запущен. Сначала запустите его."
    [SERVICE_NOT_INSTALLED]="Сервис не установлен"
    [CHECKER_VERSION]="xray-checker"
    [NOT_INSTALLED]="не установлен"

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
    [PROXY_CADDY]="Установить Caddy (авто SSL)"
    [PROXY_NGINX]="Установить Nginx"
    [PROXY_USE_EXISTING]="Использовать существующий"
    [PROXY_ADD_TO_EXISTING]="Добавить домен в"
    [PROXY_ENTER_DOMAIN]="Введите домен:"
    [DETECTING]="Определение окружения"
    [DOMAIN_CHECKING]="Проверка DNS домена..."
    [DOMAIN_OK]="Домен указывает на этот сервер"
    [DOMAIN_MISMATCH]="Домен указывает на другой IP"
    [DOMAIN_NOT_RESOLVED]="Домен не найден. Создайте A-запись, указывающую на IP сервера"
    [DOMAIN_CLOUDFLARE]="Домен проксируется через Cloudflare"
    [DOMAIN_CLOUDFLARE_HINT]="Используйте Cloudflare DNS-01 для SSL сертификата"
    [DOMAIN_SERVER_IP]="IP сервера"
    [DOMAIN_DNS_IP]="DNS домена"
    [DOMAIN_CONFIRM]="Продолжить с этим доменом?"
    [DOMAIN_CHANGE]="Ввести другой домен"
    [DOMAIN_BACK]="Вернуться назад"
    [DOMAIN_ALREADY_EXISTS]="Домен уже настроен в nginx"

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
    [API_COOKIE_INPUT_MODE]="Как вы хотите ввести данные cookie?"
    [API_COOKIE_MODE_URL]="Ввести ссылку авторизации из панели"
    [API_COOKIE_MODE_NGINX]="Вставить блок nginx config с cookie"
    [API_ENTER_AUTH_URL]="Введите ссылку авторизации из панели:"
    [API_AUTH_URL_HINT]="Формат: https://domain/auth/login?xxx=yyy"
    [API_AUTH_URL_EXAMPLE]="Пример: https://panel.example.com/auth/login?aEmFnBcC=WbYWpixX"
    [API_AUTH_URL_INVALID]="Неверный формат URL. Должен содержать ?имя=значение"
    [API_AUTH_URL_PARSED]="Cookie извлечены из URL"
    [API_NGINX_BLOCK_HINT]="Вставьте блок nginx конфига с 'map \$http_cookie' (нажмите Enter дважды для завершения):"
    [API_NGINX_BLOCK_EXAMPLE]="Пример: map \$http_cookie \$auth_cookie { default 0; \"~*aEmFnBcC=WbYWpixX\" 1; }"
    [API_NGINX_BLOCK_PARSED]="Cookie извлечены из nginx конфига"
    [API_NGINX_BLOCK_INVALID]="Не удалось извлечь cookie из nginx блока"
    [API_CHECKING_USER]="Проверка пользователя XrayChecker..."
    [API_USER_FOUND]="Пользователь XrayChecker уже существует в панели"
    [API_USER_FOUND_HINT]="Используется существующая подписка. Сквады не изменены."
    [API_USER_FOUND_CHOICE]="Пользователь XrayChecker уже существует. Что сделать?"
    [API_USER_USE_EXISTING]="Использовать существующего"
    [API_USER_RECREATE]="Удалить и создать заново (назначит сквады)"
    [API_USER_DELETING]="Удаление существующего пользователя..."
    [API_USER_DELETED]="Пользователь удалён"
    [API_CREATING_USER]="Создание пользователя XrayChecker..."
    [API_USER_CREATED]="Пользователь XrayChecker создан"
    [API_GETTING_SQUADS]="Получение Internal Squads..."
    [API_SQUADS_FOUND]="Найдено сквадов"
    [API_NO_SQUADS]="Internal Squads не найдены. Пользователь будет создан без сквадов."
    [API_SQUADS_SELECT_MODE]="Назначение сквадов пользователю XrayChecker:"
    [API_SQUADS_ALL]="Добавить все сквады"
    [API_SQUADS_SELECT]="Выбрать конкретные сквады"
    [API_SQUADS_NONE]="Без сквадов (пропустить)"
    [API_SQUADS_LIST]="Доступные сквады:"
    [API_SQUADS_ENTER_NUMBERS]="Введите номера сквадов через пробел (например, 1 3 5):"
    [API_SQUADS_SELECTED]="Выбрано сквадов"
    [API_SQUADS_HINT]="Управлять сквадами можно позже в панели Remnawave"
    [API_SUCCESS]="Подписка получена через API"
    [API_FAILED]="Ошибка получения подписки через API"
    [API_FALLBACK_MANUAL]="Ввести URL подписки вручную?"
    [API_ERROR]="Ошибка API"

    # Reverse Proxy errors
    [PROXY_ALREADY_CONFIGURED]="Reverse proxy для xray-checker уже настроен"
    [PROXY_ALREADY_HINT]="Для добавления другого домена отредактируйте nginx.conf вручную или переустановите"

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
    [SSL_WILDCARD_FOUND]="Найден wildcard сертификат"
    [SSL_WILDCARD_AUTO]="Используем wildcard сертификат автоматически"
    [SSL_ENTER_CF_TOKEN]="Введите Cloudflare API Token:"
    [SSL_ENTER_GCORE_TOKEN]="Введите Gcore API Token:"
    [SSL_ENTER_EMAIL]="Введите email:"
    [SSL_EMAIL_HINT]="Для напоминаний об истечении, без спама"
    [SSL_INVALID_EMAIL]="Неверный формат email"
    [SSL_VALIDATING_CF]="Проверка Cloudflare API токена..."
    [SSL_CF_VALID]="Cloudflare API токен действителен"
    [SSL_CF_INVALID]="Недействительный Cloudflare API токен"
    [SSL_CF_RETRY]="Введите корректный токен"
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

# Форматированный prompt в стиле [?] Text (как в install_remnawave.sh)
question() {
    echo -e "${COLOR_GREEN}[?]${COLOR_RESET} ${COLOR_YELLOW}$*${COLOR_RESET}"
}

# Чтение ввода с поддержкой редактирования
reading() {
    local prompt="$(question "$1") "
    local varname="$2"
    read -rep "$prompt" "$varname"
    # Очищаем ввод
    local cleaned
    cleaned=$(sanitize_input "${!varname}")
    printf -v "$varname" '%s' "$cleaned"
}

# Чтение обязательного поля
reading_required() {
    local prompt="$1"
    local varname="$2"
    local value=""

    while [ -z "$value" ]; do
        reading "$prompt" value

        if [ -z "$value" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
        fi
    done

    printf -v "$varname" '%s' "$value"
}

# Чтение URL
reading_url() {
    local prompt="$1"
    local varname="$2"
    local value=""

    while true; do
        reading "$prompt" value

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

# Валидация и проверка доступности URL подписки
validate_subscription_url() {
    local url="$1"
    
    # Проверка формата URL
    if [[ ! "$url" =~ ^https?:// ]] && [[ ! "$url" =~ ^file:// ]] && [[ ! "$url" =~ ^folder:// ]]; then
        echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${LANG[INVALID_URL_FORMAT]}"
        return 1
    fi
    
    # Для file:// проверяем существование файла
    if [[ "$url" =~ ^file:// ]]; then
        local filepath="${url#file://}"
        if [ ! -f "$filepath" ]; then
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${LANG[FILE_NOT_FOUND]}: ${filepath}"
            return 1
        fi
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[FILE_OK]}"
        return 0
    fi
    
    # Для folder:// проверяем существование папки
    if [[ "$url" =~ ^folder:// ]]; then
        local folderpath="${url#folder://}"
        if [ ! -d "$folderpath" ]; then
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${LANG[FOLDER_NOT_FOUND]}: ${folderpath}"
            return 1
        fi
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[FOLDER_OK]}"
        return 0
    fi
    
    # Для HTTP/HTTPS проверяем доступность
    echo -ne "${COLOR_GRAY}${LANG[CHECKING_URL]}...${COLOR_RESET}"
    
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 15 -L "$url" 2>/dev/null)
    
    # Проверка что http_code это число
    if ! [[ "$http_code" =~ ^[0-9]+$ ]]; then
        echo -e "\r${COLOR_RED}✗${COLOR_RESET} ${LANG[URL_UNREACHABLE]}               "
        return 1
    fi
    
    if [ "$http_code" = "000" ]; then
        echo -e "\r${COLOR_RED}✗${COLOR_RESET} ${LANG[URL_UNREACHABLE]}               "
        return 1
    elif [ "$http_code" -ge 400 ]; then
        echo -e "\r${COLOR_RED}✗${COLOR_RESET} ${LANG[URL_ERROR]} (HTTP $http_code)   "
        return 1
    fi
    
    echo -e "\r${COLOR_GREEN}✓${COLOR_RESET} ${LANG[URL_OK]}                          "
    return 0
}

# Чтение числа
reading_number() {
    local prompt="$1"
    local varname="$2"
    local default="${3:-}"
    local value=""

    while true; do
        if [ -n "$default" ]; then
            reading "${prompt} [${default}]" value
        else
            reading "$prompt" value
        fi

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
        reading "${prompt} (${hint})" value
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

# Проверка принадлежит ли IP к Cloudflare
is_cloudflare_ip() {
    local ip="$1"
    
    # Cloudflare IPv4 диапазоны (основные)
    local cf_ranges=(
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
    )
    
    # Простая проверка по первым октетам (быстрая)
    local first_octet="${ip%%.*}"
    case "$first_octet" in
        104|108|141|162|172|173|188|190|197|198|103|131)
            return 0
            ;;
    esac
    
    return 1
}

# Чтение домена с проверкой DNS
reading_domain() {
    local prompt="$1"
    local varname="$2"
    local value=""
    local server_ip
    local domain_ip
    local is_cloudflare=""

    server_ip=$(get_server_ip)

    while true; do
        reading "$prompt" value
        
        if [ -z "$value" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
            continue
        fi
        
        # Проверка на выход
        if [ "$value" = "0" ]; then
            printf -v "$varname" '%s' ""
            return 1
        fi

        # Убираем протокол если введён
        value=$(echo "$value" | sed 's|^https\?://||' | sed 's|/.*||')
        
        # Проверка дубликата домена в nginx.conf
        if domain_exists_in_nginx "$value"; then
            echo -e "${COLOR_YELLOW}!${COLOR_RESET} ${LANG[DOMAIN_ALREADY_EXISTS]}: $value"
            continue
        fi

        echo -ne "${COLOR_GRAY}${LANG[DOMAIN_CHECKING]}${COLOR_RESET}"

        # Получаем IP домена через несколько методов
        domain_ip=""
        is_cloudflare=""
        
        # Метод 1: dig (наиболее надёжный)
        if [ -z "$domain_ip" ] && command -v dig &>/dev/null; then
            domain_ip=$(dig +short "$value" A 2>/dev/null | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        fi
        
        # Метод 2: host
        if [ -z "$domain_ip" ] && command -v host &>/dev/null; then
            domain_ip=$(host "$value" 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
        fi
        
        # Метод 3: nslookup
        if [ -z "$domain_ip" ] && command -v nslookup &>/dev/null; then
            domain_ip=$(nslookup "$value" 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
        fi
        
        # Метод 4: getent (системный резолвер)
        if [ -z "$domain_ip" ] && command -v getent &>/dev/null; then
            domain_ip=$(getent hosts "$value" 2>/dev/null | awk '{print $1}' | grep -oE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
        fi
        
        # Метод 5: ping (последний вариант)
        if [ -z "$domain_ip" ]; then
            domain_ip=$(ping -c 1 -W 2 "$value" 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
        fi

        # Результат проверки DNS
        if [ -z "$domain_ip" ]; then
            echo -e "\r${COLOR_RED}✗${COLOR_RESET} DNS: ${LANG[DOMAIN_NOT_RESOLVED]}                    "
            continue
        elif [ "$domain_ip" = "$server_ip" ]; then
            # DNS совпадает — просто продолжаем без меню
            echo -e "\r${COLOR_GREEN}✓${COLOR_RESET} DNS: ${domain_ip} → ${LANG[DOMAIN_OK]}              "
            break
        elif is_cloudflare_ip "$domain_ip"; then
            is_cloudflare="true"
            echo -e "\r${COLOR_YELLOW}☁${COLOR_RESET} DNS: ${domain_ip} (Cloudflare)                     "
            echo -e "  ${COLOR_GRAY}${LANG[DOMAIN_CLOUDFLARE_HINT]}${COLOR_RESET}"
        else
            echo -e "\r${COLOR_YELLOW}!${COLOR_RESET} DNS: ${domain_ip} ≠ ${server_ip} (${LANG[DOMAIN_MISMATCH]})    "
        fi

        # Меню только если DNS не совпадает
        echo -e "  1. ${LANG[DOMAIN_CONFIRM]}  2. ${LANG[DOMAIN_CHANGE]}  ${COLOR_GRAY}0. ${LANG[BACK]}${COLOR_RESET}"

        local choice
        reading "${LANG[SELECT_OPTION]}" choice

        case "$choice" in
            1) break ;;
            0)
                printf -v "$varname" '%s' ""
                return 1
                ;;
            *) ;; # Повторить ввод
        esac
    done

    printf -v "$varname" '%s' "$value"
    return 0
}

# Валидация email
validate_email() {
    local email="$1"
    # Простая проверка формата email
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# Чтение email с валидацией
reading_email() {
    local prompt="$1"
    local varname="$2"
    local value=""

    while true; do
        reading "$prompt" value

        if [ -z "$value" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
            continue
        fi

        if ! validate_email "$value"; then
            echo -e "${COLOR_RED}${LANG[SSL_INVALID_EMAIL]}${COLOR_RESET}"
            continue
        fi

        break
    done

    printf -v "$varname" '%s' "$value"
}

# Проверка Cloudflare API токена
validate_cloudflare_token() {
    local token="$1"
    
    info "${LANG[SSL_VALIDATING_CF]}"
    
    # Пробуем как API Token (Bearer)
    local response
    response=$(curl -s -w "\n%{http_code}" \
        --request GET \
        --url "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        --header "Authorization: Bearer ${token}" \
        --header "Content-Type: application/json" 2>/dev/null)
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')
    
    if echo "$body" | grep -q '"success":true'; then
        success "${LANG[SSL_CF_VALID]}"
        return 0
    fi
    
    # Пробуем как Global API Key (проверяем zones)
    response=$(curl -s --request GET \
        --url "https://api.cloudflare.com/client/v4/zones" \
        --header "Authorization: Bearer ${token}" \
        --header "Content-Type: application/json" 2>/dev/null)
    
    if echo "$response" | grep -q '"success":true'; then
        success "${LANG[SSL_CF_VALID]}"
        return 0
    fi
    
    echo -e "${COLOR_RED}${LANG[SSL_CF_INVALID]}${COLOR_RESET}"
    return 1
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

# Получение версии установленного xray-checker
get_checker_version() {
    local method
    method=$(get_installer_config "INSTALL_METHOD")
    
    case "$method" in
        docker)
            # Проверяем существует ли контейнер (запущен или остановлен)
            if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "xray-checker"; then
                local version=""
                
                # Метод 1: Через API (если сервис работает)
                version=$(curl -sf --connect-timeout 2 "http://127.0.0.1:${DEFAULT_PORT:-2112}/api/v1/system/info" 2>/dev/null | grep -oP '"version"\s*:\s*"\K[^"]+' || echo "")
                if [ -n "$version" ]; then
                    echo "$version"
                    return 0
                fi
                
                # Метод 2: Из логов контейнера (даже если рестартится)
                version=$(docker logs xray-checker 2>&1 | grep -oP 'Xray Checker v\K[0-9]+\.[0-9]+\.[0-9]+' | tail -1 || echo "")
                if [ -n "$version" ]; then
                    echo "$version"
                    return 0
                fi
                
                # Метод 3: Из docker image labels
                version=$(docker inspect xray-checker 2>/dev/null | grep -oP '"XRAY_CHECKER_VERSION=\K[^"]+' || echo "")
                if [ -n "$version" ]; then
                    echo "$version"
                    return 0
                fi
                
                echo "unknown"
            else
                echo ""
            fi
            ;;
        binary)
            if command -v xray-checker &>/dev/null; then
                xray-checker --version 2>/dev/null | grep -oP 'v?\K[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown"
            else
                echo ""
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Проверка установлен ли xray-checker
is_checker_installed() {
    local method
    method=$(get_installer_config "INSTALL_METHOD")
    
    case "$method" in
        docker)
            [ -f "$FILE_COMPOSE" ] && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "xray-checker"
            ;;
        binary)
            systemctl is-enabled xray-checker &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Проверка запущен ли xray-checker
is_checker_running() {
    local method
    method=$(get_installer_config "INSTALL_METHOD")
    
    case "$method" in
        docker)
            docker ps --format '{{.Names}}' 2>/dev/null | grep -q "xray-checker"
            ;;
        binary)
            systemctl is-active --quiet xray-checker
            ;;
        *)
            return 1
            ;;
    esac
}

# Проверка существует ли домен в nginx.conf
domain_exists_in_nginx() {
    local domain="$1"
    local nginx_file="${DIR_XRAY_CHECKER}nginx.conf"
    
    if [ ! -f "$nginx_file" ]; then
        return 1
    fi
    
    grep -q "server_name.*${domain}" "$nginx_file" 2>/dev/null
}

# Проверка есть ли уже настроенный reverse proxy для xray-checker
xray_checker_proxy_exists() {
    local nginx_file="${DIR_XRAY_CHECKER}nginx.conf"
    
    if [ ! -f "$nginx_file" ]; then
        return 1
    fi
    
    # Проверяем наличие upstream или proxy_pass для xray-checker
    if grep -qE "upstream\s+xray-checker|proxy_pass.*xray-checker" "$nginx_file" 2>/dev/null; then
        return 0
    fi
    
    return 1
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

    # Сохранить выбор в конфиг
    save_installer_config "LANGUAGE" "$SELECTED_LANG"
}

load_language() {
    local saved_lang
    saved_lang=$(get_installer_config "LANGUAGE")
    if [ -n "$saved_lang" ]; then
        set_language "$saved_lang"
    else
        set_language "en"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# INSTALLER CONFIG (единый файл /etc/xray-checker/installer.conf)
# ══════════════════════════════════════════════════════════════════════════════

# Сохранить значение в конфиг установщика
save_installer_config() {
    local key="$1"
    local value="$2"
    
    mkdir -p "$DIR_INSTALLER_CONFIG"
    
    # Создать файл если не существует
    [ ! -f "$FILE_INSTALLER_CONF" ] && touch "$FILE_INSTALLER_CONF"
    
    # Удалить старое значение и добавить новое
    if grep -q "^${key}=" "$FILE_INSTALLER_CONF" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$FILE_INSTALLER_CONF"
    else
        echo "${key}=${value}" >> "$FILE_INSTALLER_CONF"
    fi
    
    chmod 600 "$FILE_INSTALLER_CONF"
}

# Получить значение из конфига установщика
get_installer_config() {
    local key="$1"
    local default="${2:-}"
    
    if [ -f "$FILE_INSTALLER_CONF" ]; then
        local value
        value=$(grep "^${key}=" "$FILE_INSTALLER_CONF" 2>/dev/null | cut -d'=' -f2-)
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi
    
    echo "$default"
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

# Извлечение cookie из nginx.conf (для eGames установки - локальный сервер)
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

# Парсинг URL авторизации для извлечения cookie
# URL формат: https://domain/auth/login?COOKIE_NAME=COOKIE_VALUE
parse_auth_url() {
    local auth_url="$1"
    
    # Проверяем что URL содержит query параметры
    if [[ ! "$auth_url" =~ \? ]]; then
        return 1
    fi
    
    # Извлекаем query string (всё после ?)
    local query_string="${auth_url#*\?}"
    
    # Разбираем первый параметр (name=value)
    # Берём часть до & если есть несколько параметров
    local first_param="${query_string%%&*}"
    
    # Проверяем формат name=value
    if [[ ! "$first_param" =~ = ]]; then
        return 1
    fi
    
    # Извлекаем имя и значение
    EGAMES_COOKIE_NAME="${first_param%%=*}"
    EGAMES_COOKIE_VALUE="${first_param#*=}"
    
    # Проверяем что оба значения не пустые
    if [ -n "$EGAMES_COOKIE_NAME" ] && [ -n "$EGAMES_COOKIE_VALUE" ]; then
        return 0
    fi
    
    return 1
}

# Парсинг nginx конфигурации для извлечения cookie
# Формат: map $http_cookie $auth_cookie { default 0; "~*COOKIE_NAME=COOKIE_VALUE" 1; }
parse_nginx_cookie_block() {
    local nginx_block="$1"
    
    # Ищем паттерн "~*NAME=VALUE" в блоке
    # Примеры:
    #   "~*aEmFnBcC=WbYWpixX" 1;
    #   '~*aEmFnBcC=WbYWpixX' 1;
    local cookie_match
    cookie_match=$(echo "$nginx_block" | grep -oE '~\*[a-zA-Z0-9]+=[a-zA-Z0-9]+' | head -n1)
    
    if [ -z "$cookie_match" ]; then
        return 1
    fi
    
    # Убираем ~* в начале
    local cookie_pair="${cookie_match#~\*}"
    
    # Извлекаем имя и значение
    EGAMES_COOKIE_NAME="${cookie_pair%%=*}"
    EGAMES_COOKIE_VALUE="${cookie_pair#*=}"
    
    # Проверяем что оба значения не пустые
    if [ -n "$EGAMES_COOKIE_NAME" ] && [ -n "$EGAMES_COOKIE_VALUE" ]; then
        return 0
    fi
    
    return 1
}

# Интерактивный ввод cookie данных
get_cookie_interactively() {
    echo ""
    echo -e "${COLOR_CYAN}${LANG[API_COOKIE_INPUT_MODE]}${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}1.${COLOR_RESET} ${LANG[API_COOKIE_MODE_URL]}"
    echo -e "  ${COLOR_WHITE}2.${COLOR_RESET} ${LANG[API_COOKIE_MODE_NGINX]}"
    echo ""
    echo -e "  ${COLOR_WHITE}0.${COLOR_RESET} ${LANG[BACK]}"
    echo ""
    
    local mode_choice
    reading "${LANG[SELECT_OPTION]}" mode_choice
    
    case "$mode_choice" in
        0)
            return 2  # Код возврата для "назад"
            ;;
        1)
            # Ввод URL авторизации
            echo ""
            echo -e "${COLOR_YELLOW}${LANG[API_AUTH_URL_HINT]}${COLOR_RESET}"
            echo -e "${COLOR_GRAY}${LANG[API_AUTH_URL_EXAMPLE]}${COLOR_RESET}"
            echo -e "${COLOR_GRAY}(0 = ${LANG[BACK]})${COLOR_RESET}"
            echo ""
            
            while true; do
                local auth_url=""
                reading "${LANG[API_ENTER_AUTH_URL]}" auth_url
                
                # Проверка на "назад"
                if [ "$auth_url" = "0" ]; then
                    return 2
                fi
                
                if [ -z "$auth_url" ]; then
                    echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
                    continue
                fi
                
                # Парсим URL
                if parse_auth_url "$auth_url"; then
                    success "${LANG[API_AUTH_URL_PARSED]}: ${EGAMES_COOKIE_NAME}=***"
                    return 0
                else
                    echo -e "${COLOR_RED}${LANG[API_AUTH_URL_INVALID]}${COLOR_RESET}"
                fi
            done
            ;;
        2)
            # Ввод nginx блока
            echo ""
            echo -e "${COLOR_YELLOW}${LANG[API_NGINX_BLOCK_HINT]}${COLOR_RESET}"
            echo -e "${COLOR_GRAY}${LANG[API_NGINX_BLOCK_EXAMPLE]}${COLOR_RESET}"
            echo -e "${COLOR_GRAY}(0 = ${LANG[BACK]})${COLOR_RESET}"
            echo ""
            
            local nginx_block=""
            local line
            
            # Читаем многострочный ввод до пустой строки
            while IFS= read -r line; do
                # Пустая строка - конец ввода
                [ -z "$line" ] && break
                # Проверка на "назад"
                [ "$line" = "0" ] && return 2
                nginx_block="${nginx_block}${line}"$'\n'
            done
            
            if [ -z "$nginx_block" ]; then
                return 2
            fi
            
            # Парсим блок
            if parse_nginx_cookie_block "$nginx_block"; then
                success "${LANG[API_NGINX_BLOCK_PARSED]}: ${EGAMES_COOKIE_NAME}=***"
                return 0
            else
                echo -e "${COLOR_RED}${LANG[API_NGINX_BLOCK_INVALID]}${COLOR_RESET}"
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
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
        # Пользователь существует — извлекаем данные
        API_SUBSCRIPTION_URL=$(echo "$body" | jq -r '.response.subscriptionUrl // empty' 2>/dev/null)
        EXISTING_USER_UUID=$(echo "$body" | jq -r '.response.uuid // empty' 2>/dev/null)
        if [ -n "$API_SUBSCRIPTION_URL" ]; then
            return 0
        fi
    fi
    
    return 1
}

# Удаление пользователя XrayChecker
delete_xraychecker_user() {
    local panel_url="$1"
    local api_token="$2"
    local cookie_header="${3:-}"
    local user_uuid="$4"
    
    if [ -z "$user_uuid" ]; then
        return 1
    fi
    
    local response
    local http_code
    
    if [ -n "$cookie_header" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -X DELETE \
            -H "Authorization: Bearer ${api_token}" \
            -H "Cookie: ${cookie_header}" \
            "${panel_url}/api/users/${user_uuid}" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" \
            -X DELETE \
            -H "Authorization: Bearer ${api_token}" \
            "${panel_url}/api/users/${user_uuid}" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "204" ]; then
        return 0
    fi
    
    return 1
}

# Получение списка Internal Squads
get_internal_squads() {
    local panel_url="$1"
    local api_token="$2"
    local cookie_header="${3:-}"
    
    local response
    local http_code
    
    if [ -n "$cookie_header" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer ${api_token}" \
            -H "Cookie: ${cookie_header}" \
            "${panel_url}/api/internal-squads" 2>/dev/null)
    else
        response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: Bearer ${api_token}" \
            "${panel_url}/api/internal-squads" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # Сохраняем полный JSON ответ для последующего использования
        INTERNAL_SQUADS_JSON=$(echo "$body" | jq -r '.response.internalSquads // []' 2>/dev/null)
        INTERNAL_SQUADS_COUNT=$(echo "$body" | jq -r '.response.total // 0' 2>/dev/null)
        
        if [ "$INTERNAL_SQUADS_COUNT" -gt 0 ] 2>/dev/null; then
            return 0
        fi
    fi
    
    INTERNAL_SQUADS_JSON="[]"
    INTERNAL_SQUADS_COUNT=0
    return 1
}

# Интерактивный выбор сквадов
select_squads_interactive() {
    local squads_json="$1"
    local squads_count="$2"
    
    # Показываем меню выбора
    echo ""
    echo -e "${COLOR_CYAN}${LANG[API_SQUADS_SELECT_MODE]}${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}1.${COLOR_RESET} ${LANG[API_SQUADS_ALL]} (${squads_count})"
    echo -e "  ${COLOR_WHITE}2.${COLOR_RESET} ${LANG[API_SQUADS_SELECT]}"
    echo -e "  ${COLOR_WHITE}3.${COLOR_RESET} ${LANG[API_SQUADS_NONE]}"
    echo ""
    
    local choice
    reading "${LANG[SELECT_OPTION]}" choice
    
    case "$choice" in
        1)
            # Все сквады
            SELECTED_SQUADS_UUIDS=$(echo "$squads_json" | jq -r '.[].uuid' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            info "${LANG[API_SQUADS_SELECTED]}: ${squads_count}"
            echo -e "${COLOR_GRAY}${LANG[API_SQUADS_HINT]}${COLOR_RESET}"
            return 0
            ;;
        2)
            # Выбор конкретных сквадов
            echo ""
            echo -e "${COLOR_WHITE}${LANG[API_SQUADS_LIST]}${COLOR_RESET}"
            
            # DEBUG: показать структуру JSON (раскомментировать для отладки)
            # echo "DEBUG JSON: $squads_json" | head -c 500
            
            # Выводим список сквадов с номерами (используем jq с индексами)
            # API возвращает: uuid, name, info.membersCount, info.inboundsCount
            local squad_list
            squad_list=$(echo "$squads_json" | jq -r 'to_entries | .[] | "  \u001b[1;33m\(.key + 1).\u001b[0m \(.value.name // "unnamed") (\(.value.info.membersCount // 0) members, \(.value.info.inboundsCount // 0) inbounds)"' 2>/dev/null)
            
            # Если jq вернул пустую строку, попробуем альтернативный формат
            if [ -z "$squad_list" ]; then
                squad_list=$(echo "$squads_json" | jq -r 'to_entries | .[] | "  \u001b[1;33m\(.key + 1).\u001b[0m \(.value.tag // .value.name // "Squad \(.key + 1)")"' 2>/dev/null)
            fi
            
            echo -e "$squad_list"
            
            echo ""
            reading "${LANG[API_SQUADS_ENTER_NUMBERS]}" selected_numbers
            
            if [ -z "$selected_numbers" ]; then
                SELECTED_SQUADS_UUIDS=""
                return 0
            fi
            
            # Преобразуем номера в UUID
            local selected_uuids=""
            for num in $selected_numbers; do
                # Проверяем что это число
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$squads_count" ]; then
                    local uuid
                    uuid=$(echo "$squads_json" | jq -r ".[$((num-1))].uuid // empty" 2>/dev/null)
                    if [ -n "$uuid" ]; then
                        [ -n "$selected_uuids" ] && selected_uuids="${selected_uuids},"
                        selected_uuids="${selected_uuids}${uuid}"
                    fi
                fi
            done
            
            SELECTED_SQUADS_UUIDS="$selected_uuids"
            
            # Подсчитываем выбранные
            local selected_count=0
            if [ -n "$SELECTED_SQUADS_UUIDS" ]; then
                selected_count=$(echo "$SELECTED_SQUADS_UUIDS" | tr ',' '\n' | wc -l)
            fi
            
            info "${LANG[API_SQUADS_SELECTED]}: ${selected_count}"
            echo -e "${COLOR_GRAY}${LANG[API_SQUADS_HINT]}${COLOR_RESET}"
            return 0
            ;;
        3|*)
            # Без сквадов
            SELECTED_SQUADS_UUIDS=""
            return 0
            ;;
    esac
}

# Создание пользователя XrayChecker
create_xraychecker_user() {
    local panel_url="$1"
    local api_token="$2"
    local cookie_header="${3:-}"
    
    # Сначала получаем список Internal Squads
    info "${LANG[API_GETTING_SQUADS]}"
    get_internal_squads "$panel_url" "$api_token" "$cookie_header"
    
    # Формируем массив activeInternalSquads для JSON
    local squads_array="[]"
    SELECTED_SQUADS_UUIDS=""
    
    if [ "$INTERNAL_SQUADS_COUNT" -gt 0 ] 2>/dev/null; then
        info "${LANG[API_SQUADS_FOUND]}: ${INTERNAL_SQUADS_COUNT}"
        
        # Интерактивный выбор сквадов
        select_squads_interactive "$INTERNAL_SQUADS_JSON" "$INTERNAL_SQUADS_COUNT"
        
        if [ -n "$SELECTED_SQUADS_UUIDS" ]; then
            # Преобразуем список UUID в JSON массив
            squads_array=$(echo "$SELECTED_SQUADS_UUIDS" | tr ',' '\n' | jq -R . | jq -s .)
        fi
    else
        warning "${LANG[API_NO_SQUADS]}"
    fi
    
    # Создаём payload с activeInternalSquads
    local payload
    payload=$(jq -n \
        --arg username "$XRAY_CHECKER_USERNAME" \
        --arg description "Auto-created by xray-checker installer for monitoring" \
        --argjson squads "$squads_array" \
        '{
            "username": $username,
            "expireAt": "2099-12-31T23:59:59.000Z",
            "trafficLimitBytes": 0,
            "trafficLimitStrategy": "NO_RESET",
            "status": "ACTIVE",
            "description": $description,
            "activeInternalSquads": $squads
        }')
    
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
            # Интерактивный ввод cookie
            local cookie_result
            get_cookie_interactively
            cookie_result=$?
            
            case $cookie_result in
                0)
                    # Успешно получили cookie
                    cookie_header="${EGAMES_COOKIE_NAME}=${EGAMES_COOKIE_VALUE}"
                    ;;
                2)
                    # Пользователь выбрал "назад"
                    return 2
                    ;;
                *)
                    # Ошибка
                    return 1
                    ;;
            esac
        fi
    fi
    
    echo ""
    info "${LANG[API_CHECKING_USER]}"
    
    # Шаг 1: Проверить существует ли пользователь
    if check_xraychecker_user "$panel_url" "$api_token" "$cookie_header"; then
        success "${LANG[API_USER_FOUND]}"
        echo -e "${COLOR_GRAY}${LANG[API_USER_FOUND_HINT]}${COLOR_RESET}"
        echo ""
        
        # Спросить что делать с существующим пользователем
        echo -e "${COLOR_CYAN}${LANG[API_USER_FOUND_CHOICE]}${COLOR_RESET}"
        echo -e "  ${COLOR_WHITE}1.${COLOR_RESET} ${LANG[API_USER_USE_EXISTING]}"
        echo -e "  ${COLOR_WHITE}2.${COLOR_RESET} ${LANG[API_USER_RECREATE]}"
        echo ""
        echo -e "  ${COLOR_WHITE}0.${COLOR_RESET} ${LANG[BACK]}"
        echo ""
        
        local user_choice
        reading "${LANG[SELECT_OPTION]}" user_choice
        
        case "$user_choice" in
            0)
                return 2
                ;;
            1)
                # Использовать существующего - URL уже в API_SUBSCRIPTION_URL
                return 0
                ;;
            2)
                # Удалить и создать заново
                info "${LANG[API_USER_DELETING]}"
                if delete_xraychecker_user "$panel_url" "$api_token" "$cookie_header" "$EXISTING_USER_UUID"; then
                    success "${LANG[API_USER_DELETED]}"
                else
                    warning "Failed to delete user, trying to create anyway..."
                fi
                # Продолжаем к созданию нового пользователя
                ;;
            *)
                # По умолчанию использовать существующего
                return 0
                ;;
        esac
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
            # Ручной ввод (с авто-добавлением https://)
            echo ""
            local sub_input=""
            while [ -z "$sub_input" ]; do
                reading "${LANG[ENTER_SUBSCRIPTION]}" sub_input
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
    while true; do
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
        local api_result
        get_subscription_via_api "$PANEL_URL" "$API_TOKEN" "$use_cookie"
        api_result=$?
        
        case $api_result in
            0)
                # Успех
                SUBSCRIPTION_URL="$API_SUBSCRIPTION_URL"
                
                # Сохранить конфигурацию API для будущего использования
                save_api_config
                
                echo ""
                success "${LANG[API_SUCCESS]}"
                echo -e "  ${COLOR_WHITE}URL:${COLOR_RESET} ${COLOR_CYAN}${SUBSCRIPTION_URL}${COLOR_RESET}"
                echo ""
                
                read -r -p "${LANG[PRESS_ENTER]}"
                return 0
                ;;
            2)
                # Пользователь выбрал "назад" - вернуться к выбору типа установки
                echo ""
                continue
                ;;
            *)
                # Ошибка
                echo ""
                warning "${LANG[API_FAILED]}"
                echo ""
                
                # Предложить ввести вручную
                local fallback
                reading_yn "${LANG[API_FALLBACK_MANUAL]}" fallback "y"
                
                if [ "$fallback" = "y" ]; then
                    reading_url "${LANG[ENTER_SUBSCRIPTION]}" SUBSCRIPTION_URL
                    return 0
                fi
                
                return 1
                ;;
        esac
    done
}

# Сохранение конфигурации API
save_api_config() {
    save_installer_config "PANEL_URL" "$PANEL_URL"
    save_installer_config "API_TOKEN" "$API_TOKEN"
    save_installer_config "SUBSCRIPTION_MODE" "api"
    save_installer_config "XRAY_CHECKER_USERNAME" "$XRAY_CHECKER_USERNAME"
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

    # 4. Проверка НАШЕГО nginx (в папке xray-checker)
    if [ -f "${DIR_XRAY_CHECKER}nginx.conf" ]; then
        DETECTED_PROXY="own_nginx"
        DETECTED_PROXY_PATH="${DIR_XRAY_CHECKER}nginx.conf"
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 5. Проверка системного Nginx (с защитой от ошибок)
    if command -v systemctl &>/dev/null && systemctl is-active --quiet nginx 2>/dev/null; then
        DETECTED_PROXY="system_nginx"
        DETECTED_PROXY_PATH="/etc/nginx/sites-available/"
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 6. Проверка Docker nginx (внешний, не наш)
    if command -v docker &>/dev/null && docker ps --format '{{.Names}}' 2>/dev/null | grep -qiE "nginx|remnawave-nginx"; then
        DETECTED_PROXY="docker_nginx"
        # Определить путь к конфигурации Docker nginx
        # Сначала проверяем известные пути
        if [ -d "/opt/nginx/conf.d" ]; then
            DETECTED_PROXY_PATH="/opt/nginx/conf.d"
        elif [ -d "/opt/remnawave/nginx" ]; then
            DETECTED_PROXY_PATH="/opt/remnawave/nginx"
        else
            # Попробуем найти путь из Docker volumes
            local nginx_container
            nginx_container=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -iE "nginx|remnawave-nginx" | head -1)
            if [ -n "$nginx_container" ]; then
                # Ищем volume mount для conf.d или nginx.conf
                local conf_mount
                conf_mount=$(docker inspect "$nginx_container" 2>/dev/null | grep -oP '(?<="Source": ")[^"]*(?=.*conf)' | head -1)
                if [ -n "$conf_mount" ] && [ -d "$conf_mount" ]; then
                    DETECTED_PROXY_PATH="$conf_mount"
                fi
            fi
        fi
        [ -d "/etc/letsencrypt/live" ] && DETECTED_CERTS="letsencrypt"
        return 0
    fi

    # 6. Проверка системного Caddy (с защитой от ошибок)
    if command -v systemctl &>/dev/null && systemctl is-active --quiet caddy 2>/dev/null; then
        DETECTED_PROXY="system_caddy"
        DETECTED_PROXY_PATH="/etc/caddy/Caddyfile"
        return 0
    fi

    # 7. Проверка Docker caddy
    if command -v docker &>/dev/null && docker ps --format '{{.Names}}' 2>/dev/null | grep -qiE "caddy|remnawave-caddy"; then
        DETECTED_PROXY="docker_caddy"
        return 0
    fi

    # Ничего не найдено — это нормально
    return 0
}

get_proxy_display_name() {
    case "$DETECTED_PROXY" in
        egames_nginx)      echo "eGames Nginx (Remnawave)" ;;
        remnawave_caddy)   echo "Remnawave Caddy" ;;
        remnawave_nginx)   echo "Remnawave Nginx" ;;
        own_nginx)         echo "Nginx (xray-checker)" ;;
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
HAS_SSL=""  # "true" если SSL успешно настроен

# Глобальные переменные для сбора настроек (фаза вопросов)
SETUP_PROXY_TYPE=""      # "nginx", "caddy", "existing_nginx", "existing_caddy"
SETUP_DOMAIN=""          # Домен для xray-checker
SETUP_SSL_METHOD=""      # "cloudflare", "acme", "gcore", "existing", "skip" (skip для Caddy)
SETUP_CF_TOKEN=""        # Cloudflare API токен
SETUP_GCORE_TOKEN=""     # Gcore API токен
SETUP_CERT_EMAIL=""      # Email для Let's Encrypt
SETUP_EXISTING_CERT=""   # Путь к существующему сертификату

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

# Извлечь базовый домен из субдомена: sub.example.com → example.com
extract_base_domain() {
    local subdomain="$1"
    echo "$subdomain" | awk -F'.' '{if (NF > 2) {print $(NF-1)"."$NF} else {print $0}}'
}

# Проверить является ли сертификат wildcard
# Возвращает 0 если сертификат содержит wildcard (*.domain)
is_wildcard_cert() {
    local cert_dir="$1"
    local cert_path="/etc/letsencrypt/live/$cert_dir/fullchain.pem"

    if [ ! -f "$cert_path" ]; then
        return 1
    fi

    # Проверяем наличие любого wildcard (*.) в Subject Alternative Names
    if openssl x509 -noout -text -in "$cert_path" 2>/dev/null | grep -qE "DNS:\*\."; then
        return 0
    fi
    
    return 1
}

# Получить домены из сертификата (Subject Alternative Names)
get_cert_domains() {
    local cert_dir="$1"
    local cert_path="/etc/letsencrypt/live/$cert_dir/fullchain.pem"
    
    if [ ! -f "$cert_path" ]; then
        return 1
    fi
    
    # Извлекаем все DNS имена из SAN
    openssl x509 -noout -text -in "$cert_path" 2>/dev/null | \
        grep -oP 'DNS:\K[^,\s]+' | tr '\n' ' '
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
            # Проверяем wildcard и получаем домены
            local cert_domains
            cert_domains=$(get_cert_domains "$name")
            
            # Ищем wildcard в доменах сертификата
            local wildcard_domain
            wildcard_domain=$(echo "$cert_domains" | grep -oE '\*\.[^ ]+' | head -1)
            
            if [ -n "$wildcard_domain" ]; then
                certs+=("$wildcard_domain")
            else
                certs+=("$name")
            fi
        fi
    done
    
    if [ ${#certs[@]} -eq 0 ]; then
        return 1
    fi
    
    printf '%s\n' "${certs[@]}"
    return 0
}

# Найти подходящий wildcard сертификат для домена
# Например: для checker.example.com ищем сертификат с *.example.com
find_matching_wildcard() {
    local domain="$1"
    
    if [ ! -d "/etc/letsencrypt/live" ]; then
        return 1
    fi
    
    # Извлекаем базовый домен (example.com из sub.example.com)
    local base_domain
    base_domain=$(extract_base_domain "$domain")
    
    if [ -z "$base_domain" ]; then
        return 1
    fi
    
    # Проверяем что это субдомен первого уровня (wildcard покрывает только один уровень)
    local subdomain_part="${domain%.$base_domain}"
    if [[ "$subdomain_part" =~ \. ]]; then
        # Это субдомен второго+ уровня (deep.sub.example.com) — wildcard не подходит
        return 1
    fi
    
    # Ищем wildcard сертификат среди всех сертификатов
    local wildcard_pattern="*.${base_domain}"
    
    for cert_dir in /etc/letsencrypt/live/*/; do
        local name=$(basename "$cert_dir")
        [ "$name" = "README" ] && continue
        [ ! -f "${cert_dir}fullchain.pem" ] && continue
        
        # Получаем домены из сертификата
        local cert_domains
        cert_domains=$(get_cert_domains "$name")
        
        # Проверяем есть ли нужный wildcard
        if echo "$cert_domains" | grep -qF "$wildcard_pattern"; then
            WILDCARD_CERT_DOMAIN="$name"
            WILDCARD_BASE_DOMAIN="$base_domain"
            return 0
        fi
    done
    
    return 1
}

# Сбор настроек SSL (только вопросы, без установки)
collect_ssl_settings() {
    local domain="$1"
    
    # Сброс предыдущих настроек
    SETUP_SSL_METHOD=""
    SETUP_CF_TOKEN=""
    SETUP_GCORE_TOKEN=""
    SETUP_CERT_EMAIL=""
    SETUP_EXISTING_CERT=""
    WILDCARD_CERT_DOMAIN=""
    WILDCARD_BASE_DOMAIN=""
    
    echo ""
    echo -e "  ${COLOR_CYAN}SSL ${LANG[SSL_DOMAIN]}: ${domain}${COLOR_RESET}"
    
    # Проверяем есть ли подходящий wildcard сертификат
    if find_matching_wildcard "$domain"; then
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[SSL_WILDCARD_FOUND]}: ${COLOR_YELLOW}*.${WILDCARD_BASE_DOMAIN}${COLOR_RESET}"
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[SSL_WILDCARD_AUTO]}"
        echo ""
        
        SETUP_SSL_METHOD="existing"
        SETUP_EXISTING_CERT="$WILDCARD_CERT_DOMAIN"
        return 0
    fi
    
    # Проверить существующие сертификаты
    local existing_certs
    existing_certs=$(list_available_certs 2>/dev/null)
    
    if [ -n "$existing_certs" ]; then
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${LANG[SSL_EXISTING_FOUND]}:"
        echo "$existing_certs" | while read -r cert; do
            echo -e "    ${COLOR_GRAY}• ${cert}${COLOR_RESET}"
        done
    fi
    echo ""
    
    echo -e "  ${COLOR_WHITE}1.${COLOR_RESET} Cloudflare DNS ${COLOR_GRAY}(API token)${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}2.${COLOR_RESET} ACME HTTP-01 ${COLOR_GRAY}(port 80)${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}3.${COLOR_RESET} Gcore DNS ${COLOR_GRAY}(API token)${COLOR_RESET}"
    [ -n "$existing_certs" ] && echo -e "  ${COLOR_WHITE}4.${COLOR_RESET} ${LANG[SSL_USE_EXISTING]}"
    echo -e "  ${COLOR_GRAY}0. ${LANG[SSL_SKIP]}${COLOR_RESET}"
    echo ""
    
    local choice
    while true; do
        reading "${LANG[SELECT_OPTION]}" choice
        
        # Пустой ввод — показать ошибку и повторить
        if [ -z "$choice" ]; then
            echo -e "${COLOR_RED}${LANG[INVALID_CHOICE]}${COLOR_RESET}"
            continue
        fi
        
        case "$choice" in
            0)
                SETUP_SSL_METHOD="skip"
                return 1
                ;;
            1)
                SETUP_SSL_METHOD="cloudflare"
                reading "${LANG[SSL_ENTER_CF_TOKEN]}" SETUP_CF_TOKEN
                reading_email "${LANG[SSL_ENTER_EMAIL]}" SETUP_CERT_EMAIL
                
                # Валидация токена после сбора всех данных
                if [ -n "$SETUP_CF_TOKEN" ]; then
                    if ! validate_cloudflare_token "$SETUP_CF_TOKEN"; then
                        SETUP_SSL_METHOD="skip"
                        return 1
                    fi
                else
                    echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
                    SETUP_SSL_METHOD="skip"
                    return 1
                fi
                return 0
                ;;
            2)
                SETUP_SSL_METHOD="acme"
                reading_email "${LANG[SSL_ENTER_EMAIL]}" SETUP_CERT_EMAIL
                return 0
                ;;
            3)
                SETUP_SSL_METHOD="gcore"
                reading "${LANG[SSL_ENTER_GCORE_TOKEN]}" SETUP_GCORE_TOKEN
                
                if [ -z "$SETUP_GCORE_TOKEN" ]; then
                    echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
                    SETUP_SSL_METHOD="skip"
                    return 1
                fi
                
                reading_email "${LANG[SSL_ENTER_EMAIL]}" SETUP_CERT_EMAIL
                return 0
                ;;
            4)
                if [ -n "$existing_certs" ]; then
                    SETUP_SSL_METHOD="existing"
                    echo -e "${LANG[SSL_SELECT_CERT]}:"
                    echo "$existing_certs" | nl -w2 -s'. ' | sed 's/^/  /'
                    
                    local cert_num
                    reading "${LANG[SSL_ENTER_CERT_NUM]}" cert_num
                    local selected_cert
                    selected_cert=$(echo "$existing_certs" | sed -n "${cert_num}p")
                    
                    # Если выбран wildcard — найти папку с этим сертификатом
                    if [[ "$selected_cert" == \*.* ]]; then
                        # Ищем папку содержащую этот wildcard
                        local wildcard_pattern="$selected_cert"
                        for cert_dir in /etc/letsencrypt/live/*/; do
                            local dir_name=$(basename "$cert_dir")
                            [ "$dir_name" = "README" ] && continue
                            local cert_domains=$(get_cert_domains "$dir_name")
                            if echo "$cert_domains" | grep -qF "$wildcard_pattern"; then
                                SETUP_EXISTING_CERT="$dir_name"
                                break
                            fi
                        done
                    else
                        SETUP_EXISTING_CERT="$selected_cert"
                    fi
                    
                    [ -n "$SETUP_EXISTING_CERT" ] && return 0
                fi
                SETUP_SSL_METHOD="skip"
                return 1
                ;;
            *)
                # Неверный ввод — показать ошибку и повторить
                echo -e "${COLOR_RED}${LANG[INVALID_CHOICE]}${COLOR_RESET}"
                continue
                ;;
        esac
    done
}

# Применение настроек SSL (выполнение установки)
apply_ssl_settings() {
    local domain="$1"
    
    case "$SETUP_SSL_METHOD" in
        cloudflare)
            get_cert_cloudflare "$domain" "$SETUP_CERT_EMAIL" "$SETUP_CF_TOKEN"
            return $?
            ;;
        acme)
            get_cert_acme_standalone "$domain" "$SETUP_CERT_EMAIL"
            return $?
            ;;
        gcore)
            get_cert_gcore "$domain" "$SETUP_CERT_EMAIL" "$SETUP_GCORE_TOKEN"
            return $?
            ;;
        existing)
            use_existing_certs "$SETUP_EXISTING_CERT"
            return $?
            ;;
        skip|*)
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
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
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
# ВАЖНО: Эта функция использует уже собранные настройки (SETUP_SSL_METHOD, SETUP_EXISTING_CERT)
# и НЕ должна задавать вопросы!
add_to_nginx() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local nginx_conf="$DETECTED_PROXY_PATH"
    local cert_path=""

    # DEBUG: показать значения переменных
    # echo "DEBUG: SETUP_SSL_METHOD=$SETUP_SSL_METHOD"
    # echo "DEBUG: SETUP_EXISTING_CERT=$SETUP_EXISTING_CERT"
    # echo "DEBUG: DETECTED_PROXY=$DETECTED_PROXY"

    # Определить путь к сертификату из уже собранных настроек
    case "$SETUP_SSL_METHOD" in
        cloudflare|acme|gcore)
            cert_path="/etc/letsencrypt/live/${domain}"
            ;;
        existing)
            if [ -n "$SETUP_EXISTING_CERT" ]; then
                cert_path="/etc/letsencrypt/live/${SETUP_EXISTING_CERT}"
            else
                warning "SETUP_EXISTING_CERT is empty"
                cert_path=""
            fi
            ;;
        skip|"")
            cert_path=""
            ;;
    esac

    # Проверить что сертификаты есть (если нужны)
    if [ -n "$cert_path" ] && [ ! -d "$cert_path" ]; then
        warning "SSL certificates not found at: ${cert_path}"
        cert_path=""
    fi

    # Создать backup если файл существует
    if [ -f "$nginx_conf" ]; then
        cp "$nginx_conf" "${nginx_conf}.backup.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    fi

    # Генерируем конфиг
    local nginx_block
    if [ -n "$cert_path" ]; then
        nginx_block=$(generate_nginx_block "$domain" "$port" "$cert_path")
        HAS_SSL="true"
    else
        # HTTP-only конфиг
        nginx_block=$(cat <<EOF
# xray-checker HTTP config (added by xchecker installer)
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
)
        HAS_SSL=""
    fi

    # Применяем конфиг в зависимости от типа nginx
    case "$DETECTED_PROXY" in
        egames_nginx)
            # eGames: добавляем в конец файла
            echo "$nginx_block" >> "$nginx_conf"
            ;;
        docker_nginx)
            # Docker nginx — нужен путь к конфигам
            if [ -z "$DETECTED_PROXY_PATH" ]; then
                warning "Docker nginx config path not found. Please configure manually."
                echo -e "${COLOR_YELLOW}Nginx config block:${COLOR_RESET}"
                echo "$nginx_block"
                return 1
            fi
            
            # Если путь это директория conf.d — пишем отдельный файл
            if [[ "$DETECTED_PROXY_PATH" == *conf.d* ]] || [[ "$DETECTED_PROXY_PATH" == *conf\.d* ]]; then
                echo "$nginx_block" > "${DETECTED_PROXY_PATH}/xray-checker.conf"
            else
                # Иначе добавляем в nginx.conf
                echo "$nginx_block" >> "${DETECTED_PROXY_PATH}/nginx.conf"
            fi
            
            # Копируем сертификаты если есть (в ту же директорию)
            if [ -n "$cert_path" ] && [ -d "$cert_path" ]; then
                local certs_dir="${DETECTED_PROXY_PATH%/conf.d}/certs"
                mkdir -p "$certs_dir"
                cp "${cert_path}/fullchain.pem" "$certs_dir/"
                cp "${cert_path}/privkey.pem" "$certs_dir/"
                # Меняем пути в конфиге на Docker-пути
                local conf_file
                if [[ "$DETECTED_PROXY_PATH" == *conf.d* ]]; then
                    conf_file="${DETECTED_PROXY_PATH}/xray-checker.conf"
                else
                    conf_file="${DETECTED_PROXY_PATH}/nginx.conf"
                fi
                sed -i 's|ssl_certificate .*fullchain.pem;|ssl_certificate /etc/nginx/certs/fullchain.pem;|' "$conf_file"
                sed -i 's|ssl_certificate_key .*privkey.pem;|ssl_certificate_key /etc/nginx/certs/privkey.pem;|' "$conf_file"
                # Меняем proxy_pass на Docker network
                sed -i 's|proxy_pass http://127.0.0.1:|proxy_pass http://xray-checker:|' "$conf_file"
            fi
            ;;
        own_nginx)
            # Наш собственный nginx в папке xray-checker
            # При добавлении нового домена:
            # 1. Добавить server block в nginx.conf (в конец файла)
            # 2. Добавить volume mount для сертификата в docker-compose.yml
            # ВАЖНО: upstream и глобальные SSL настройки уже есть в начале файла
            local nginx_file="$DETECTED_PROXY_PATH"
            local cert_domain=""
            
            # Определяем домен сертификата
            if [ -n "$cert_path" ]; then
                cert_domain=$(basename "$cert_path")
            fi
            
            # Создаём новый server block для дополнительного домена
            # Используем существующий upstream xray-checker и глобальные SSL настройки
            local new_server_block=""
            if [ -n "$cert_path" ] && [ -n "$cert_domain" ]; then
                new_server_block="
# Redirect HTTP to HTTPS for ${domain}
server {
    listen 80;
    server_name ${domain};
    return 301 https://\$host\$request_uri;
}

# HTTPS server for ${domain}
server {
    listen 443 ssl;
    http2 on;
    server_name ${domain};

    ssl_certificate /etc/nginx/ssl/${cert_domain}/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/${cert_domain}/privkey.pem;
    ssl_trusted_certificate /etc/nginx/ssl/${cert_domain}/fullchain.pem;

    location / {
        proxy_http_version 1.1;
        proxy_pass http://xray-checker;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
"
                HAS_SSL="true"
                
                # Добавляем volume mount для нового сертификата в docker-compose.yml
                # Проверяем не добавлен ли уже этот сертификат
                if ! grep -q "/etc/letsencrypt/live/${cert_domain}/fullchain.pem" "$FILE_COMPOSE" 2>/dev/null; then
                    # Добавляем перед строкой "depends_on:"
                    sed -i "/depends_on:/i\\      - /etc/letsencrypt/live/${cert_domain}/fullchain.pem:/etc/nginx/ssl/${cert_domain}/fullchain.pem:ro" "$FILE_COMPOSE"
                    sed -i "/depends_on:/i\\      - /etc/letsencrypt/live/${cert_domain}/privkey.pem:/etc/nginx/ssl/${cert_domain}/privkey.pem:ro" "$FILE_COMPOSE"
                fi
            else
                new_server_block="
# HTTP server for ${domain}
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_http_version 1.1;
        proxy_pass http://xray-checker;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
"
                HAS_SSL=""
            fi
            
            # Добавляем новый server block в конец файла
            echo "$new_server_block" >> "$nginx_file"
            ;;
        system_nginx)
            # Системный nginx: sites-available/sites-enabled
            if [ -d "/etc/nginx/sites-available" ]; then
                echo "$nginx_block" > /etc/nginx/sites-available/xray-checker
                ln -sf /etc/nginx/sites-available/xray-checker /etc/nginx/sites-enabled/xray-checker
            elif [ -d "/etc/nginx/conf.d" ]; then
                echo "$nginx_block" > /etc/nginx/conf.d/xray-checker.conf
            else
                warning "Unknown nginx config structure"
                return 1
            fi
            ;;
        *)
            # Неизвестный тип — пытаемся найти conf.d
            if [ -d "/etc/nginx/conf.d" ]; then
                echo "$nginx_block" > /etc/nginx/conf.d/xray-checker.conf
            else
                warning "Cannot determine nginx config path"
                return 1
            fi
            ;;
    esac

    # Проверка конфигурации и перезагрузка
    reload_nginx

    return 0
}

# Перезагрузка nginx (определяет тип автоматически)
reload_nginx() {
    if [ "$DETECTED_PROXY" = "egames_nginx" ] || [ "$DETECTED_PROXY" = "docker_nginx" ]; then
        # Docker nginx (внешний)
        local container_name
        container_name=$(docker ps --format '{{.Names}}' | grep -iE "nginx|remnawave-nginx" | head -1)
        if [ -n "$container_name" ]; then
            # Проверка конфигурации
            if ! docker exec "$container_name" nginx -t 2>/dev/null; then
                warning "Nginx configuration test failed"
                return 1
            fi
            # Перезагрузка
            docker exec "$container_name" nginx -s reload 2>/dev/null || {
                # Если reload не работает — перезапуск контейнера
                docker restart "$container_name" 2>/dev/null
            }
        fi
    elif [ "$DETECTED_PROXY" = "own_nginx" ]; then
        # Наш собственный nginx в той же папке
        if docker ps --format '{{.Names}}' | grep -q "^nginx$"; then
            # Проверка конфигурации
            if ! docker exec nginx nginx -t 2>/dev/null; then
                warning "Nginx configuration test failed"
                return 1
            fi
            # Перезагрузка
            docker exec nginx nginx -s reload 2>/dev/null || {
                docker restart nginx 2>/dev/null
            }
        fi
    else
        # System nginx
        if command -v nginx &>/dev/null; then
            nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null
        fi
    fi
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

    HAS_SSL="true"  # Caddy автоматически получает SSL
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

    docker compose pull >/dev/null 2>&1
    docker compose up -d >/dev/null 2>&1

    DETECTED_PROXY="docker_caddy"
    DETECTED_PROXY_PATH="/opt/caddy/Caddyfile"
    HAS_SSL="true"  # Caddy автоматически получает SSL

    success "Caddy installed with auto SSL"
}

# Меню настройки Reverse Proxy (ФАЗА 1: Сбор данных)
# Reverse proxy ОБЯЗАТЕЛЕН — без него установка невозможна
# Параметр: $1 = "no_clear" - не очищать экран
collect_reverse_proxy_settings() {
    local no_clear="${1:-}"
    
    if [ "$no_clear" != "no_clear" ]; then
        clear_screen
    fi
    
    # Пустая строка перед заголовком (отделение от предыдущего блока)
    echo ""
    
    # Компактный заголовок
    echo -e "${COLOR_CYAN}── ${LANG[PROXY_TITLE]} ──${COLOR_RESET}"

    # Сброс настроек
    SETUP_PROXY_TYPE=""
    SETUP_DOMAIN=""
    XCHECKER_DOMAIN=""
    INCLUDE_NGINX=""
    INCLUDE_CADDY=""

    # Определение окружения
    echo -ne "${COLOR_GRAY}${LANG[DETECTING]}...${COLOR_RESET}"
    detect_reverse_proxy
    
    local proxy_name
    proxy_name=$(get_proxy_display_name)

    if [ "$DETECTED_PROXY" != "none" ]; then
        echo -e "\r${COLOR_GREEN}✓${COLOR_RESET} ${LANG[PROXY_DETECTED]}: ${COLOR_CYAN}${proxy_name}${COLOR_RESET}     "
    else
        echo -e "\r${COLOR_YELLOW}! ${LANG[PROXY_NONE]}${COLOR_RESET}                    "
    fi

    # Варианты меню — всегда показываем все опции
    local choice
    if [ "$DETECTED_PROXY" != "none" ]; then
        # Proxy найден — первый вариант "использовать существующий"
        echo -e "  1. ${LANG[PROXY_ADD_TO_EXISTING]} ${proxy_name}"
        echo -e "  2. Caddy ${COLOR_GRAY}(auto SSL)${COLOR_RESET}"
        echo -e "  ${COLOR_GRAY}0. ${LANG[BACK]}${COLOR_RESET}"
        reading "${LANG[SELECT_OPTION]}" choice

        case "$choice" in
            1)
                # Использовать существующий proxy
                reading_domain "${LANG[PROXY_ENTER_DOMAIN]}" SETUP_DOMAIN
                [ -z "$SETUP_DOMAIN" ] && return 1

                case "$DETECTED_PROXY" in
                    *nginx*) SETUP_PROXY_TYPE="existing_nginx" ;;
                    *caddy*) SETUP_PROXY_TYPE="existing_caddy" ;;
                esac

                # Для nginx нужны SSL настройки, для Caddy — нет (auto SSL)
                if [ "$SETUP_PROXY_TYPE" = "existing_nginx" ]; then
                    if ! collect_ssl_settings "$SETUP_DOMAIN"; then
                        # Пользователь отменил выбор SSL — вернуться назад
                        SETUP_PROXY_TYPE=""
                        SETUP_DOMAIN=""
                        return 1
                    fi
                fi
                
                XCHECKER_DOMAIN="$SETUP_DOMAIN"
                return 0
                ;;
            2)
                # Установить Caddy
                SETUP_PROXY_TYPE="caddy"
                reading_domain "${LANG[PROXY_ENTER_DOMAIN]}" SETUP_DOMAIN
                [ -z "$SETUP_DOMAIN" ] && return 1
                XCHECKER_DOMAIN="$SETUP_DOMAIN"
                return 0
                ;;
            *) return 1 ;;
        esac
    else
        # Proxy НЕ найден — предлагаем установить
        echo -e "  1. Nginx ${COLOR_GRAY}(${LANG[RECOMMENDED]})${COLOR_RESET}"
        echo -e "  2. Caddy ${COLOR_GRAY}(auto SSL)${COLOR_RESET}"
        echo -e "  ${COLOR_GRAY}0. ${LANG[BACK]}${COLOR_RESET}"
        reading "${LANG[SELECT_OPTION]}" choice

        case "$choice" in
            1)
                SETUP_PROXY_TYPE="nginx"
                INCLUDE_NGINX="true"  # Будет добавлен в docker-compose.yml
                reading_domain "${LANG[PROXY_ENTER_DOMAIN]}" SETUP_DOMAIN
                [ -z "$SETUP_DOMAIN" ] && return 1
                if ! collect_ssl_settings "$SETUP_DOMAIN"; then
                    SETUP_PROXY_TYPE=""
                    SETUP_DOMAIN=""
                    INCLUDE_NGINX=""
                    return 1
                fi
                XCHECKER_DOMAIN="$SETUP_DOMAIN"
                return 0
                ;;
            2)
                SETUP_PROXY_TYPE="caddy"
                INCLUDE_CADDY="true"  # Будет добавлен в docker-compose.yml
                reading_domain "${LANG[PROXY_ENTER_DOMAIN]}" SETUP_DOMAIN
                [ -z "$SETUP_DOMAIN" ] && return 1
                XCHECKER_DOMAIN="$SETUP_DOMAIN"
                return 0
                ;;
            *) return 1 ;;
        esac
    fi
    
    return 0
}

# Применение настроек Reverse Proxy (ФАЗА 2: Установка)
apply_reverse_proxy_settings() {
    local port="${1:-$DEFAULT_PORT}"
    
    case "$SETUP_PROXY_TYPE" in
        existing_nginx)
            info "Configuring existing Nginx..."
            # Сначала получаем SSL если нужно
            if [ "$SETUP_SSL_METHOD" != "skip" ] && [ -n "$SETUP_SSL_METHOD" ]; then
                apply_ssl_settings "$SETUP_DOMAIN"
            fi
            add_to_nginx "$SETUP_DOMAIN" "$port"
            success "Reverse proxy configured for ${SETUP_DOMAIN}"
            ;;
        existing_caddy)
            info "Configuring existing Caddy..."
            add_to_caddy "$SETUP_DOMAIN" "$port"
            success "Reverse proxy configured for ${SETUP_DOMAIN}"
            ;;
        nginx)
            info "Installing Nginx..."
            # Сначала получаем SSL если нужно
            if [ "$SETUP_SSL_METHOD" != "skip" ] && [ -n "$SETUP_SSL_METHOD" ]; then
                apply_ssl_settings "$SETUP_DOMAIN"
            fi
            install_nginx_docker_no_questions "$SETUP_DOMAIN" "$port"
            ;;
        caddy)
            info "Installing Caddy..."
            install_caddy_docker "$SETUP_DOMAIN" "$port"
            ;;
        skip|*)
            # Ничего не делать
            return 0
            ;;
    esac
}

# Установка Nginx Docker БЕЗ вопросов (использует уже собранные настройки)
# Nginx создаётся в той же папке /opt/xray-checker/ и том же docker-compose.yml
# Сертификаты монтируются напрямую из /etc/letsencrypt/ (автообновление certbot)
install_nginx_docker_no_questions() {
    local domain="$1"
    local port="${2:-$DEFAULT_PORT}"
    local cert_path=""
    local cert_domain=""  # Домен для сертификата (может отличаться от domain для wildcard)

    # Определить путь к сертификату из собранных настроек
    case "$SETUP_SSL_METHOD" in
        cloudflare|acme|gcore)
            cert_path="/etc/letsencrypt/live/${domain}"
            cert_domain="${domain}"
            ;;
        existing)
            cert_path="/etc/letsencrypt/live/${SETUP_EXISTING_CERT}"
            cert_domain="${SETUP_EXISTING_CERT}"
            ;;
        *)
            cert_path=""
            cert_domain=""
            ;;
    esac

    # Проверить что сертификаты есть напрямую в /etc/letsencrypt/live/
    if [ -n "$cert_domain" ]; then
        local letsencrypt_path="/etc/letsencrypt/live/${cert_domain}"
        if [ ! -d "$letsencrypt_path" ] || [ ! -f "${letsencrypt_path}/fullchain.pem" ]; then
            warning "SSL certificates not found at: ${letsencrypt_path}"
            cert_path=""
            cert_domain=""
        fi
    fi

    cd "$DIR_XRAY_CHECKER" 2>/dev/null || { mkdir -p "$DIR_XRAY_CHECKER" && cd "$DIR_XRAY_CHECKER"; }

    # Создать nginx.conf (server blocks only, монтируется как default.conf)
    # Структура как в install_remnawave.sh
    if [ -n "$cert_domain" ] && [ -d "/etc/letsencrypt/live/${cert_domain}" ]; then
        # HTTPS конфигурация
        cat > nginx.conf <<EOF
# xray-checker nginx configuration
# Generated by xchecker installer

upstream xray-checker {
    server xray-checker:2112;
}

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ""      close;
}

# SSL settings
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ecdh_curve X25519:prime256v1:secp384r1;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers off;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name ${domain};
    return 301 https://\$host\$request_uri;
}

# HTTPS server for ${domain}
server {
    listen 443 ssl;
    http2 on;
    server_name ${domain};

    ssl_certificate /etc/nginx/ssl/${cert_domain}/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/${cert_domain}/privkey.pem;
    ssl_trusted_certificate /etc/nginx/ssl/${cert_domain}/fullchain.pem;

    location / {
        proxy_http_version 1.1;
        proxy_pass http://xray-checker;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
        HAS_SSL="true"
        # Сохраняем домен сертификата для docker-compose volumes
        NGINX_CERT_DOMAIN="$cert_domain"
    else
        # HTTP-only конфигурация
        cat > nginx.conf <<EOF
# xray-checker nginx configuration
# Generated by xchecker installer

upstream xray-checker {
    server xray-checker:2112;
}

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ""      close;
}

# HTTP server for ${domain}
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_http_version 1.1;
        proxy_pass http://xray-checker;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
        HAS_SSL=""
        NGINX_CERT_DOMAIN=""
    fi

    # Помечаем что nginx наш (в той же папке)
    DETECTED_PROXY="own_nginx"
    DETECTED_PROXY_PATH="${DIR_XRAY_CHECKER}nginx.conf"
    
    # INCLUDE_NGINX уже установлен в collect_reverse_proxy_settings
    INCLUDE_NGINX="true"
    
    # Сохраняем данные для повторных запусков
    save_installer_config "PROXY_TYPE" "nginx"
    [ -n "$NGINX_CERT_DOMAIN" ] && save_installer_config "CERT_DOMAIN" "$NGINX_CERT_DOMAIN"
}

# Функция для настройки/перенастройки reverse proxy из меню управления
setup_reverse_proxy() {
    # Проверяем, есть ли уже настроенный reverse proxy
    if xray_checker_proxy_exists; then
        echo ""
        warning "${LANG[PROXY_ALREADY_CONFIGURED]}"
        echo -e "${COLOR_GRAY}${LANG[PROXY_ALREADY_HINT]}${COLOR_RESET}"
        echo ""
        read -r -p "${LANG[PRESS_ENTER]}"
        return 0
    fi
    
    collect_reverse_proxy_settings
    if [ -n "$SETUP_PROXY_TYPE" ] && [ -n "$SETUP_DOMAIN" ]; then
        echo ""
        info "Starting installation..."
        apply_reverse_proxy_settings "$DEFAULT_PORT"
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

    # Проверяем сохранённый флаг (для повторных запусков)
    local saved_proxy_type
    saved_proxy_type=$(get_installer_config "PROXY_TYPE")
    if [ "$saved_proxy_type" = "nginx" ]; then
        INCLUDE_NGINX="true"
    fi
    
    # Читаем сохранённый домен сертификата
    # Но проверяем что сертификат реально существует в /etc/letsencrypt/live/
    local saved_cert_domain
    saved_cert_domain=$(get_installer_config "CERT_DOMAIN")
    if [ -n "$saved_cert_domain" ] && [ -d "/etc/letsencrypt/live/${saved_cert_domain}" ]; then
        NGINX_CERT_DOMAIN="$saved_cert_domain"
    else
        NGINX_CERT_DOMAIN=""
    fi

    # Начинаем docker-compose.yml
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
EOF

    # Если нужен nginx, добавляем его сервис
    if [ "$INCLUDE_NGINX" = "true" ]; then
        cat >> "$FILE_COMPOSE" <<EOF

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
EOF

        # Добавляем монтирование сертификатов напрямую из /etc/letsencrypt/
        # Это позволяет certbot автоматически обновлять сертификаты
        if [ -n "$NGINX_CERT_DOMAIN" ] && [ -d "/etc/letsencrypt/live/${NGINX_CERT_DOMAIN}" ]; then
            cat >> "$FILE_COMPOSE" <<EOF
      - /etc/letsencrypt/live/${NGINX_CERT_DOMAIN}/fullchain.pem:/etc/nginx/ssl/${NGINX_CERT_DOMAIN}/fullchain.pem:ro
      - /etc/letsencrypt/live/${NGINX_CERT_DOMAIN}/privkey.pem:/etc/nginx/ssl/${NGINX_CERT_DOMAIN}/privkey.pem:ro
EOF
        fi

        cat >> "$FILE_COMPOSE" <<EOF
    depends_on:
      - xray-checker
EOF
    fi

    # Завершаем файл секцией networks
    cat >> "$FILE_COMPOSE" <<EOF

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
    save_installer_config "INSTALL_METHOD" "binary"

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

    echo -e "${COLOR_GRAY}${LANG[QUICK_INSTALL_DESC]}${COLOR_RESET}"
    echo -e "${COLOR_GRAY}${LANG[ENTER_0_TO_BACK]}${COLOR_RESET}"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # ФАЗА 1: СБОР ДАННЫХ (все вопросы)
    # ═══════════════════════════════════════════════════════════════════════════

    # 1. Запрос подписки (URL, file://, folder://)
    local sub_url=""
    while true; do
        local sub_input=""
        reading "${LANG[ENTER_SUBSCRIPTION]}" sub_input
        
        # Проверка на выход
        if [ "$sub_input" = "0" ]; then
            return
        fi
        
        if [ -z "$sub_input" ]; then
            echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
            continue
        fi
        
        # Автоматически добавляем https:// если не указан протокол
        if [[ ! "$sub_input" =~ ^https?:// ]] && [[ ! "$sub_input" =~ ^file:// ]] && [[ ! "$sub_input" =~ ^folder:// ]]; then
            sub_url="https://${sub_input}"
        else
            sub_url="$sub_input"
        fi
        
        # Валидация URL
        if validate_subscription_url "$sub_url"; then
            break
        fi
        # Если валидация не прошла — повторить ввод
    done

    # 2. Настройка Reverse Proxy (обязательно, без очистки экрана)
    local bind_host="127.0.0.1"
    
    # Сбор настроек reverse proxy (домен, SSL метод, токены)
    collect_reverse_proxy_settings "no_clear"
    
    # Если пользователь отменил — вернуться в меню
    if [ -z "$SETUP_PROXY_TYPE" ] || [ -z "$SETUP_DOMAIN" ]; then
        return
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # ФАЗА 2: УСТАНОВКА (без вопросов)
    # ═══════════════════════════════════════════════════════════════════════════

    echo ""
    info "${LANG[STARTING_SERVICE]}"

    info "${LANG[CHECKING_SYSTEM]}"

    # Проверки и установка зависимостей
    check_os
    install_packages
    install_docker

    # Создание Docker-сети если нет
    docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1 || \
        docker network create "$DOCKER_NETWORK" >/dev/null 2>&1

    # Создание директории (сначала перейти в безопасное место)
    cd /tmp 2>/dev/null || cd /
    mkdir -p "$DIR_XRAY_CHECKER"
    cd "$DIR_XRAY_CHECKER" || { error "Cannot change to $DIR_XRAY_CHECKER"; return 1; }

    # Генерация учётных данных
    generate_credentials

    # Подготовка reverse proxy (создаёт nginx.conf/Caddyfile, сертификаты)
    # Должно быть ДО generate_docker_compose, т.к. устанавливает INCLUDE_NGINX
    apply_reverse_proxy_settings "$DEFAULT_PORT"

    # Генерация конфигурации (учитывает INCLUDE_NGINX/INCLUDE_CADDY)
    info "${LANG[CREATING_CONFIG]}"
    generate_env_file "$sub_url" "$DEFAULT_PORT" "true" "$METRICS_USERNAME" "$METRICS_PASSWORD" "false"
    generate_docker_compose "$DEFAULT_PORT" "$bind_host"

    # Сохранение метода установки
    save_installer_config "INSTALL_METHOD" "docker"

    # Запуск всех сервисов (xray-checker + nginx/caddy если нужно)
    info "${LANG[STARTING_SERVICE]}"
    docker compose pull >/dev/null 2>&1
    docker compose up -d >/dev/null 2>&1

    # Проверка здоровья (даём время на запуск)
    info "${LANG[CHECKING_HEALTH]}"
    local health_ok=false
    for i in {1..10}; do
        sleep 2
        if curl -sf "http://127.0.0.1:${DEFAULT_PORT}/health" >/dev/null 2>&1; then
            health_ok=true
            break
        fi
    done
    
    if [ "$health_ok" = true ]; then
        success "${LANG[CHECKING_HEALTH]}"
    else
        warning "${LANG[ERROR_HEALTH]}"
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

    echo -e "${COLOR_GRAY}${LANG[CUSTOM_INSTALL_DESC]}${COLOR_RESET}"
    echo -e "${COLOR_GRAY}${LANG[ENTER_0_TO_BACK]}${COLOR_RESET}"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # ФАЗА 1: СБОР ДАННЫХ (все вопросы)
    # ═══════════════════════════════════════════════════════════════════════════

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
            # Ручной ввод (как в quick_install)
            echo ""
            while true; do
                local sub_input=""
                reading "${LANG[ENTER_SUBSCRIPTION]}" sub_input
                
                # Проверка на выход
                if [ "$sub_input" = "0" ]; then
                    return
                fi
                
                if [ -z "$sub_input" ]; then
                    echo -e "${COLOR_RED}${LANG[FIELD_REQUIRED]}${COLOR_RESET}"
                    continue
                fi
                
                # Автоматически добавляем https:// если не указан протокол
                if [[ ! "$sub_input" =~ ^https?:// ]] && [[ ! "$sub_input" =~ ^file:// ]] && [[ ! "$sub_input" =~ ^folder:// ]]; then
                    sub_url="https://${sub_input}"
                else
                    sub_url="$sub_input"
                fi
                
                # Валидация URL
                if validate_subscription_url "$sub_url"; then
                    break
                fi
            done
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

    # 6. Reverse Proxy (обязательно, без очистки экрана)
    collect_reverse_proxy_settings "no_clear"
    
    # Если пользователь отменил — вернуться в меню
    if [ -z "$SETUP_PROXY_TYPE" ] || [ -z "$SETUP_DOMAIN" ]; then
        return
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # ФАЗА 2: УСТАНОВКА (без вопросов)
    # ═══════════════════════════════════════════════════════════════════════════

    echo ""
    info "${LANG[STARTING_SERVICE]}"

    info "${LANG[CHECKING_SYSTEM]}"

    # Проверки и установка зависимостей
    check_os
    install_packages

    local bind_host="127.0.0.1"

    case "$install_method" in
        1|docker|"")
            install_docker

            # Создание Docker-сети если нет
            docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1 || \
                docker network create "$DOCKER_NETWORK" >/dev/null 2>&1

            # Создание директории (сначала перейти в безопасное место)
            cd /tmp 2>/dev/null || cd /
            mkdir -p "$DIR_XRAY_CHECKER"
            cd "$DIR_XRAY_CHECKER" || { error "Cannot change to $DIR_XRAY_CHECKER"; return 1; }

            # Подготовка reverse proxy (создаёт nginx.conf/Caddyfile, сертификаты)
            # Должно быть ДО generate_docker_compose, т.к. устанавливает INCLUDE_NGINX
            apply_reverse_proxy_settings "$port"

            # Генерация конфигурации (учитывает INCLUDE_NGINX/INCLUDE_CADDY)
            info "${LANG[CREATING_CONFIG]}"
            generate_env_file "$sub_url" "$port" "$protected" "$username" "$password" "$web_public"
            generate_docker_compose "$port" "$bind_host"

            # Сохранение метода установки
            save_installer_config "INSTALL_METHOD" "docker"

            # Запуск всех сервисов (xray-checker + nginx/caddy если нужно)
            info "${LANG[STARTING_SERVICE]}"
            docker compose pull >/dev/null 2>&1
            docker compose up -d >/dev/null 2>&1
            ;;
        2|binary)
            install_binary_method "$sub_url" "$port" "$protected" "$username" "$password" "$web_public"
            ;;
    esac

    # Проверка здоровья (даём время на запуск)
    info "${LANG[CHECKING_HEALTH]}"
    local health_ok=false
    for i in {1..10}; do
        sleep 2
        if curl -sf "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
            health_ok=true
            break
        fi
    done
    
    if [ "$health_ok" = true ]; then
        success "${LANG[CHECKING_HEALTH]}"
    else
        warning "${LANG[ERROR_HEALTH]}"
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
    echo -e "    ${COLOR_WHITE}${LANG[USERNAME]}:${COLOR_RESET}  ${COLOR_YELLOW}${METRICS_USERNAME}${COLOR_RESET}"
    echo -e "    ${COLOR_WHITE}${LANG[PASSWORD]}:${COLOR_RESET}  ${COLOR_YELLOW}${METRICS_PASSWORD}${COLOR_RESET}"
    echo ""
    echo -e "    ${COLOR_GRAY}${LANG[CREDENTIALS_HINT]}${COLOR_RESET}"
    echo -e "    ${COLOR_GRAY}${LANG[CREDENTIALS_FILE]}: ${FILE_ENV}${COLOR_RESET}"
    echo ""
}

show_install_success() {
    local port="${1:-$DEFAULT_PORT}"
    local ip
    ip=$(get_server_ip)

    echo ""
    echo -e "  ${COLOR_GREEN}✅ ${LANG[INSTALL_COMPLETE]}${COLOR_RESET}"
    echo ""
    
    # Если есть домен с SSL — показываем только HTTPS
    if [ -n "$XCHECKER_DOMAIN" ] && [ "$HAS_SSL" = "true" ]; then
        echo -e "    ${COLOR_WHITE}${LANG[WEB_INTERFACE]}:${COLOR_RESET}  ${COLOR_CYAN}https://${XCHECKER_DOMAIN}${COLOR_RESET}"
    elif [ -n "$XCHECKER_DOMAIN" ]; then
        echo -e "    ${COLOR_WHITE}${LANG[WEB_INTERFACE]}:${COLOR_RESET}  ${COLOR_CYAN}http://${XCHECKER_DOMAIN}${COLOR_RESET}"
    else
        echo -e "    ${COLOR_WHITE}${LANG[WEB_INTERFACE]}:${COLOR_RESET}  ${COLOR_CYAN}http://${ip}:${port}${COLOR_RESET}"
    fi
    echo ""
    
    echo -e "    ${COLOR_WHITE}${LANG[RERUN_CMD]}:${COLOR_RESET} ${COLOR_YELLOW}xchecker${COLOR_RESET}"
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
    local method
    method=$(get_installer_config "INSTALL_METHOD")

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
    local method
    method=$(get_installer_config "INSTALL_METHOD")

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
    # Проверяем, запущен ли сервис
    if ! is_checker_running; then
        warning "${LANG[SERVICE_NOT_RUNNING]}"
        read -r -p "${LANG[PRESS_ENTER]}"
        return
    fi
    
    local method
    method=$(get_installer_config "INSTALL_METHOD")

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
    local method
    method=$(get_installer_config "INSTALL_METHOD")

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
    local method
    method=$(get_installer_config "INSTALL_METHOD")

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
    local method
    method=$(get_installer_config "INSTALL_METHOD")

    # Перейти в безопасное место перед удалением
    cd /tmp 2>/dev/null || cd /

    case "$method" in
        docker)
            # Остановка и удаление контейнера
            if [ -f "$FILE_COMPOSE" ]; then
                cd "$DIR_XRAY_CHECKER" 2>/dev/null && docker compose down -v 2>/dev/null
                cd /tmp 2>/dev/null || cd /
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
                cd "$DIR_XRAY_CHECKER" 2>/dev/null && docker compose down -v 2>/dev/null
                cd /tmp 2>/dev/null || cd /
                docker rmi "$DOCKER_IMAGE" 2>/dev/null
            fi
            if systemctl is-active --quiet xray-checker 2>/dev/null; then
                uninstall_binary
            fi
            ;;
    esac

    # Удаление директорий
    rm -rf "$DIR_XRAY_CHECKER"
    rm -rf "$DIR_INSTALLER_CONFIG"

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

        # Получаем версию установленного xray-checker
        local checker_version=""
        local checker_status=""
        if is_checker_installed; then
            checker_version=$(get_checker_version)
            if is_checker_running; then
                checker_status="●"
            else
                checker_status="○"
            fi
        fi

        echo ""
        print_box_top 60
        print_box_empty 60
        print_box_line_text "${COLOR_WHITE}▀▄▀ █▀█ ▄▀█ █▄█ ▄▄ █▀▀ █░█ █▀▀ █▀▀ █▄▀ █▀▀ █▀█${COLOR_RESET}" 60
        print_box_line_text "${COLOR_WHITE}█░█ █▀▄ █▀█ ░█░ ░░ █▄▄ █▀█ ██▄ █▄▄ █░█ ██▄ █▀▄${COLOR_RESET}" 60
        print_box_empty 60
        print_box_line_text "${COLOR_GRAY}${LANG[VERSION]}: ${SCRIPT_VERSION}${COLOR_RESET}" 60
        
        # Показываем версию xray-checker если установлен
        if [ -n "$checker_version" ]; then
            if [ "$checker_status" = "●" ]; then
                print_box_line_text "${COLOR_GREEN}${checker_status}${COLOR_RESET} ${COLOR_GRAY}${LANG[CHECKER_VERSION]}: ${checker_version}${COLOR_RESET}" 60
            else
                print_box_line_text "${COLOR_YELLOW}${checker_status}${COLOR_RESET} ${COLOR_GRAY}${LANG[CHECKER_VERSION]}: ${checker_version}${COLOR_RESET}" 60
            fi
        else
            print_box_line_text "${COLOR_GRAY}${LANG[CHECKER_VERSION]}: ${LANG[NOT_INSTALLED]}${COLOR_RESET}" 60
        fi
        
        print_box_empty 60
        print_box_bottom 60
        echo ""

        print_menu_item "1" "🚀 ${LANG[MENU_QUICK_INSTALL]}" "${LANG[RECOMMENDED]}"
        print_menu_item "2" "⚙️  ${LANG[MENU_CUSTOM_INSTALL]}"
        print_menu_item "3" "📊 ${LANG[MENU_MANAGE]}"
        print_menu_item "4" "🔄 ${LANG[MENU_UPDATE_SCRIPT]}"
        print_menu_item "5" "🗑️  ${LANG[MENU_UNINSTALL]}"
        print_menu_item "6" "🌐 ${LANG[MENU_LANGUAGE]}"
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
            6) select_language ;;
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
    local saved_lang
    saved_lang=$(get_installer_config "LANGUAGE")
    if [ -n "$saved_lang" ]; then
        load_language
    else
        select_language
    fi

    # Главное меню
    main_menu
}

# Запуск
main "$@"
