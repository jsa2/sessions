const {decode} = require('jsonwebtoken')

let token = process.argv.pop()

console.log(decode(token))

