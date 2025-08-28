function cleanTitle(title) {
  return title.replace(/[\/\\:\[\]|]/g, '-'); // Replace illegal filename characters with '-'
}

module.exports = { cleanTitle };