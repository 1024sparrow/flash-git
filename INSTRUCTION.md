# Инструкция настройки системы на автомонтирование флешки

## Инициализация флешки

```bash
sudo mkfs.ext4 /dev/sdb -U "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
```
UUID вы задаёте явно. Это чтоб потом не выяснять UUID получившейся флешки.

## Настройка автомонтирования флешки

Выбираем путь монтирования флешки. Для каждой флешки должен быть свой путь монтирования.
У нас кажая регистрируемая флешка имеет свой внутренний числовой идентификатор (число от 1 до 100). Вот его и отражаем в пути монтирования.
>Обратите внимание на то, что путь монтирования отражён также в имени конфигурационных файлов. Если это не соблюдать, то правила работать не будут (будет ошибка времени исполнения)

```/etc/systemd/system/usr-share-flashgit-1.mount```:
```
[Unit]
Description=flashgit media with UUID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

[Mount]
What=/dev/disk/by-uuid/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Where=/usr/share/flashgit/1
Type=ext4
Options=user,rw,sync
DirectoryMode=0755
TimeoutSec=2

[Install]
WantedBy=multi-user.target
```

```/etc/systemd/system/usr-share-flashgit-1.mount```:
```
Description=Automount Additional Drive

[Automount]
Where=/usr/share/flashgit/1234

[Install]
WantedBy=multi-user.target
```

Перезагружаем систему и радуемся жизни.

Теперь монтирование флешки происходит по обращении к директории /usr/share/flashgit/1 .

## Настраиваем репозитории для работы с флешкой

### Случай с не-bare репозиториями (т.е. которые созданы ```git init``` или ```git clone```)

Пусть синхронизируемый репозиторий у нас лежит по пути ```/home/boris/repos/kuku```. Судя по имени, это не-bare репозиторий.
Склонируем с него bare-репозиторий на примонтированной флешке. Поскольку флешка у нас автоматически монтируется с рутовыми правами, то команды запускаем из-под рута:

Заходим на флешку по пути ```/usr/share/flashgit/1```:
```bash
git init --bare --shared=true kuku.git
chown -R <USER> kuku.git
chgrp -R <USER> kuku.git
```
На флешке должнa появиться директория kuku.git, и теперь не надо быjть рутом, чтобы вносить изменения в этот репозиторий.

Заходим в репозиторий, который надо будет синхронизировать.
Если вы склонировали репозиторий откуда-то по сети, и хотите дальше пушить по умолчанию туда же, то делаем отдельный ```remote```
```bash
git remote add flashgit /usr/share/flashgit/1/kuku.git
```

Если хотите пушить по умолчанию прямо на флешку, то
```bash
git remote add origin /usr/share/flashgit/1/kuku.git
```
