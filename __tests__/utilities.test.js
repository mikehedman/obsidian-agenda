const { cleanTitle } = require('../utilities');

test('cleanTitle should return a title', () => {
  const title = 'Meeting: [Project]/Update?*<>| &';
  expect(cleanTitle(title)).toBe('Meeting- -Project--Update?*<>- &');
})