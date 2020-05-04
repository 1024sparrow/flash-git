# flash-git
> Utility for synchronizing via a USB flash drive local git repositories on computers not connected by a network

There is README [in Russian](README-ru.md)

This tool is intended for
- ensuring storage of the repository on a flash drive;
- synchronization of repositories on different computers via a flash drive by simply inserting and removing a flash drive;
- recovery of the flash drive from the local replica of the repository on any of the computers.

This may be applicable for the following purposes:
- Collaboration of people on computers that are not connected by a network.
- Duplication of data on different computers. An alternative to using RAID arrays.
- Rapid software updates at the customer's site without going online.

## Requirements and Current Issues

The current version is 0.

At the moment, the utility works only on Linux.

In addition, this utility (version 0) has a number of limitations (due to bugs and deficiencies):
* You can work only on Linux. Moreover, the flash drives created now will not work with future versions of flash-git (during the upgrade, it will require reinitialization of all the used flash drives; now the ext4 file system is used, which cannot be used in Windows, it is planned to switch to FAT-32 for synchronization of repositories on computers with different operating systems systems and with different file system support).
* The involved local repositories can have any number of "git remote", but after registering the local repository in flash-git with git in those local repositories, all git operations can be done only under root. When flash-git is updated, the rights to the git service files will be restored.
* In the list of paths to local directories, if your local repository is somewhere in the bowels of the home directory, instead of "/ home / $ USER /", write "~ /". Auto-replacement of such things does not work now, and a user with a different name will have problems with read-write permissions during synchronization, since his home directory is in a different path.
* To synchronize with a USB flash drive after insertion, you must also run "flash-git --device = <FILE-DEVICE-USB Flash Drive>". It was not possible to make synchronization automatic by using only "udev rules" (Linux-specific) when inserting a flash drive (problems arise when calling "git push"), but has not yet been implemented through a monitoring daemon.
* You cannot sync more than 100 repositories through one USB flash drive.
* In synchronized repositories, you cannot create, delete or rename the flash-git branch.

The repository synchronization process is logged to the file /usr/share/flash-git/log

## Installation

> select a location to download this repository so that this repository is not subsequently deleted, renamed or moved - after installation, flash-git system files will refer to files from the repository you downloaded

After downloading this repository, run the install.sh script from under the root

Subsequently, if you want to update the version of flash-git, you just have to do a "git pull". If the release of the new version stipulates that there is no compatibility with previous versions, you should perform "./uninstall.sh" before upgrading, and "./install.sh" after upgrading, and all previous registrations of flash drives will be reset.

# Creating a flash drive (initializing a flash drive)

To register a USB flash drive as a carrier of your local repositories, create a text file (for example, *my-repositories*) and write the paths to those repositories that you want to store on the USB flash drive.
```bash
/home/user/some_dir/00309_test_git_1
/home/user/some_dir/00309_test_git_2
```
These must be initialized git repositories. Their presence *origin* does not matter.

Insert a flash drive. Do not mount it. Look at which device file your flash drive is displayed in (in this case, "sdb"):
As root, run flash-git with the following arguments:
> The first time the flash drive is initialized, it will be formatted. All data on it will be destroyed!
```bash
$ sudo flash-git --device = /dev/sdb --alias=myFlash_00309 --repo-list=my-repositories
```
The --alias option is required. This is the identifier of the flash drive, additional to its serial number. Allows you to see a more readable identifier than the serial number when displaying a list of registered flash drives. It is recommended to include the flash drive initialization date in *alias*: this will be useful when you reinitialize the flash drives (in order to transfer one local repository to another flash drive, you need to register the old one and reinitialize the old one - this is where it will be useful see the date of the current flash drive initialization)

During the first initialization, the list of paths to the repositories specified in my-repositories is saved on the USB flash drive, as well as the local repositories themselves are cloned to the USB flash drive (not in such a way that you can work directly with them on the USB flash drive).

## Initializing a flash drive for local repositories:

When initializing local repositories, it checks for the presence of such directories in the file system. If at least one directory from the list of synchronized repositories already exists, flash-git will display a message about the problem and will not do anything.

To initialize local repositories by flash drive, you need to run flash-git with the following arguments:
```bash
$ sudo flash-git --device=/dev/sdb --user=$USER --group=$USER
```
Local repositories will be cloned from the flash drive along the paths written to the flash drive when it is initialized.
You can already work with these repositories.

## Sync local repositories and flash drives

To synchronize local repositories and flash drives, run flash-git with a single argument:
```bash
$ sudo flash-git --device=/dev/sdb
```

## Help and Support

The utility allows you to bind a USB flash drive, untie the USB flash drive, list the registered USB flash drives, and also restore the lost USB flash drive (initialize the USB flash drive according to the registration data of another USB flash drive, after which the old USB flash drive will not work, but the new one will work).
To see all flash-git options, run flash-git with the argument "--help":
```bash
$ flash-git --help
```

If there are any problems, please write [HERE] (https://github.com/1024sparrow/flash-git/issues/new) or to me personally by mail (1024sparrow@gmail.com).

Copyright © 2020 Boris Vasilev. [License MIT](https://github.com/1024sparrow/flash-git/blob/master/LICENSE)
