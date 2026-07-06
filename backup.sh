echo "starting backup"
mkdir -p backup
cp notes.txt backup/notes_backup_$(date +%Y%m%d).txt
echo "Backup completed! check the back up folder"
ls /backup
