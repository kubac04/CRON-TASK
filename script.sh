#!/bin/bash

CONFIG_FILE="/var/backup_files_list"
DESTINATION="/backup"
DATA=$(date +%Y-%m-%d)
LOG_FILE="/var/log/backup.log"
BACKUP="${DESTINATION}/backup_${DATA}.tar.gz"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

load_files() {
    if [ -f "$CONFIG_FILE" ]; then
        mapfile -t SOURCE < "$CONFIG_FILE"
    else
        echo "Brak pliku konfiguracyjnego, proszę wprowadzić listę plików."
        request_files
    fi
}

request_files() {
    echo "Podaj ścieżki plików, oddzielając je spacjami (np. /sciezka/do/pliku1 /sciezka/do/pliku2):"
    read -r -a SOURCE
    echo "Czy zapisać te pliki na przyszłość? [t/n]"
    read -r SAVE_CHOICE
    if [[ "$SAVE_CHOICE" == "t" || "$SAVE_CHOICE" == "T" ]]; then
        printf "%s\n" "${SOURCE[@]}" > "$CONFIG_FILE"
        echo "Lista plików zapisana w $CONFIG_FILE"
    fi
}

if [ ! -d "$DESTINATION" ]; then
    log_message "Tworzę nowy katalog docelowy: $DESTINATION"
    mkdir -p "$DESTINATION"
    if [ $? -ne 0 ]; then
        log_message "Nie udało się utworzyć katalogu $DESTINATION"
        exit 1
    fi
fi

load_files

if [ ${#SOURCE[@]} -eq 0 ]; then
    echo "Brak plików do backupu. Anulowano."
    exit 1
fi

log_message "Tworzenie kopii zapasowej"
tar -czf "$BACKUP" "${SOURCE[@]}" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "Kopia zakończona sukcesem: $BACKUP"
else
    log_message "Błąd podczas tworzenia kopii zapasowej: $BACKUP"
    exit 1
fi
