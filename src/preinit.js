const express = require('express')
const path = require('path')
const fs = require('fs')
const appInit = express()
const http = require('http')
const https = require('https')
const cookieParser = require('cookie-parser')
appInit.use(express.urlencoded({extended:true}))
appInit.use(express.json())
appInit.use(cookieParser())

console.log('running pre-init')


function init () {

    if (process.env['WEBSITE_HOSTNAME']) {
 /*        appInit.use(require('./fdidcheck').CheckAzureFrontDoor('776f6b81-1790-4d8a-88da-2379d2fc9599')) */
        console.log('checking for existing port', process.env.PORT)
        var port = process.env.PORT 
        appInit.listen(port, () => {
            console.log('AzureVersionRunning', "on port", port)
            }) 

    }

    else {
        console.log('local version')

        var serveroptions = {
            key: fs.readFileSync ('priv.key'),
            cert: fs.readFileSync ('pub.crt'),
            requestCert: false,
            rejectUnauthorized: false,
        }
    
        var server = https.createServer( serveroptions, appInit)
        var httpserver = http.createServer(appInit)

        server.listen (443, () => { 
        console.log('https')}
        )


        httpserver.listen(80, () => {
        console.log('http')
        })

    }
   
    return appInit

}


module.exports={init,express}
