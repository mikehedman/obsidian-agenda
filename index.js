const sqlite3 = require("sqlite3").verbose();
const path = require("path");
const fs = require("fs");
const { exec } = require('child_process');
const { cleanTitle } = require('./utilities');

// Constants - need to be customized
const dailyNoteTitle = "Today's Meetings.md"
// Path to macOS Calendar DB
const dbPath = "/Users/mike/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb";
const calendarName = "WorkCalendar";
const vaultPath = "/Users/mike/Library/Mobile Documents/iCloud~md~obsidian/Documents/Mikes iCloud Notes";

// Open DB
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_READONLY, (err) => {
  if (err) {
    console.error("Error opening calendar DB:", err.message);
    process.exit(1);
  }
});

// Mac calendar stores dates as seconds since 2001-01-01
const macEpoch = new Date("2001-01-01T00:00:00Z").getTime() / 1000;

let midnight = new Date();
midnight.setHours(0, 0, 0, 0);

//adjust for how sqlite works with dates
let beginDay = new Date((midnight.getTime()/1000 - macEpoch));
const beginDaySeconds = beginDay.getTime();
let endDay = new Date();
endDay.setHours(23, 59, 59, 999);
endDay = new Date((endDay.getTime()/1000 - macEpoch));

function writePage(events) {
  const formatter = new Intl.DateTimeFormat('en-US', {
    hour: 'numeric', // 'numeric' (e.g., 5), '2-digit' (e.g., 05)
    minute: '2-digit',
    hour12: true // true for 12-hour format with AM/PM, false for 24-hour format
  });

  let pageText = `# Calendar Events for ${midnight.toDateString()}\n\n`;
  if (events.length !== 0) {
    events.forEach(event => {
      pageText += `${formatter.format(event.start)}`;
      pageText += `- ${formatter.format(event.end)}   `;
      pageText += `**[[${cleanTitle(event.title)}]]**  \n\n`;
    });
  } else {
    pageText += "\n\n#### No meetings today!\n";
  }
  pageText += `\n\n<p align="right">Generated on ${new Date().toLocaleString()}</p>\n`;

  fs.writeFile(path.join(vaultPath, dailyNoteTitle), pageText, (err) => {
    if (err) {
      console.error('Error writing to file:', err);
      return;
    }
    console.log('File written successfully! ' + new Date().toLocaleString());
  });
}

function runQuery(sql, params) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) {
        reject(err);
      } else {
        resolve(rows);
      }
    });
  });
}

async function main() {
  try {
    const rows = await runQuery(
      `SELECT *,
        ci.summary AS title, 
        oc.occurrence_date, 
        oc.occurrence_end_date 
       FROM OccurrenceCache oc
       JOIN Calendar cal ON ci.calendar_id = cal.ROWID
       INNER JOIN CalendarItem ci ON oc.event_id = ci.orig_item_id OR oc.event_id = ci.ROWID
       WHERE cal.title = '${calendarName}'
         AND oc.day = ${beginDaySeconds}
         AND ci.start_date = (
            SELECT MAX(ci2.start_date) 
            FROM CalendarItem ci2
            WHERE ci2.orig_item_id = oc.event_id OR ci2.ROWID = oc.event_id
         )
       ORDER BY oc.occurrence_date
       LIMIT 20;`
    );

    const daysEvents = [];
    rows.forEach((row) => {
      const start = new Date((row.occurrence_date + macEpoch) * 1000);
      const end = new Date((row.occurrence_end_date + macEpoch) * 1000);
      daysEvents.push({title: row.title, start, end});
      console.log(`📅 ${row.title} [${row.calendar_name}] OC Start: ${start}  End: ${end}`);
    });

    writePage(daysEvents);
  } catch (err) {
    console.error("Query error:", err.message);
  } finally {
    db.close();
  }
}

main();