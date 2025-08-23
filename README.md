# obsidian-agenda
Creates a daily agenda view in Obsidian based on a Mac calendar. This code is very specific to how Mac Calendar stores its data, so Windows or Linux use is not supported.

### Installation
1. Clone or download this repository.
2. CD into the directory and run `npm install` to install dependencies.
3. Edit lines in the `// Constants` section in `index.js` to set your preferences:
- `dailyNoteTitle`: Name for the daily agenda note.
- `dbPath`: Path to the Calendar database file.
- `calendarName`: Name of the Mac calendar to pull events from.
- `vaultPath`: Path to your Obsidian vault.
Note: if you will be using a cron job to run the script, make sure to use absolute paths.

### Usage
Run the script with `node index.js`. It will create or update a daily agenda note in your Obsidian vault with events from the specified Mac calendar for the current day.

##### cron Job (Optional)
To automate the agenda creation, you can set up a cron job to run the script at a specific time each day. For example, to run it every day at 7 AM, add the following line to your crontab (edit with `crontab -e`):
```0 7 * * * /usr/local/bin/node /path/to/your/repo/index.js``` 
Make sure to replace `/usr/local/bin/node` with the path to your Node.js binary and `/path/to/your/repo/index.js` with the path to the script.
Personally, I've set it to run hourly on weekdays to keep my agenda up to date throughout the day. I've also added logging to capture any errors or output from the script. Here's the cron job line I used:"
```0 * * * 1-5 /usr/local/bin/node /path/to/your/repo/index.js >> /path/to/your/repo/cron_log 2>&1```

When run via a cron job, node will probably not have permission to open the Mac Calendar database. 
**How to grant Full Disk Access:**
1. Go to **System Settings > Privacy & Security > Full Disk Access**.
2. Click the `+` icon.
3. Press `Command + Shift + G` to bring up the "Go to Folder" dialog and type `/usr/local/bin` (change this if your nodejs is installed somewhere else!).
4. Select `node` from the list and click "Open".

### Notes
- For quick access to the daily agenda note in Obsidian, I pinned it to the sidebar. 
- I was not able to find any comprehensive documentation on the structure of the Mac Calendar database - particularly for recurring events. So this script may not cover all edge cases. Feel free to modify it to suit your needs.
