# flash-git
>Instruction and scripts for creating git-repositories on flash-drives and it's automatic mount-pull-push-unmount.

Данный инструмент предназначен для
- обеспечения хранения репозитория на флэшке;
- синхронизации репозиториев на разных компьютерах через флэшку;
- восстановления флэшки-носителя с локальной реплики репозитория на любом из компьютеров.

Флэшка-носитель может быть только одна - нельзя сделать резервную копию.

Данный инструмент не работает на операционных ситемах MS DOS, MS Windows, Колибри и Menuet.

# Создание флэшки-носителя

Вставьте флэшку. Не монтируйте её. Посмотрите, в какой файл устройства отобразилась ваша влэшка (в данном случае, "sdb"):
```bash
$ dmesg | tail
[140914.594706] scsi host6: usb-storage 1-1.1.4:1.0
[140915.885470] scsi 6:0:0:0: Direct-Access     UFD 2.0  Silicon-Power4G  1100 PQ: 0 ANSI: 4
[140915.887133] sd 6:0:0:0: Attached scsi generic sg1 type 0
[140915.893635] sd 6:0:0:0: [sdb] 7864320 512-byte logical blocks: (4.03 GB/3.75 GiB)
[140915.894374] sd 6:0:0:0: [sdb] Write Protect is off
[140915.894381] sd 6:0:0:0: [sdb] Mode Sense: 43 00 00 00
[140915.895122] sd 6:0:0:0: [sdb] No Caching mode page found
[140915.895137] sd 6:0:0:0: [sdb] Assuming drive cache: write through
[140915.900535]  sdb:
[140915.904123] sd 6:0:0:0: [sdb] Attached SCSI removable disk
```
От имени root-а запустите скрипт install.sh, указав при этом путь до устройства флэшки ("/dev/sdb"):
```bash
# sudo ./install.sh /dev/sdb
```
