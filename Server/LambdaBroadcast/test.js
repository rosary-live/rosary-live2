var moment = require('moment');

console.log(moment().format());
console.log(moment().utc().format());
console.log(moment().format('X'));
console.log(moment().utc().format('X'));
