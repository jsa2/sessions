
const { createContainerV2, uploadV2, getSasUrlV2 } = require('./src/storagev2')


const { argv } = require("yargs");
const accountName = argv?.sa || process?.argv[2]


createStorage(accountName,'useMIoutside.md').catch(err => {
    console.log(err)
})

async function createStorage (accountName, file, filePath) {

    await createContainerV2(accountName, 'demo').catch(error => {
        console.log( error )
        throw new Error('Unable to work with storage',error)
    })


    let res = await uploadV2(accountName, 'demo', file, `./${file}`)
    console.log(res)

    return ;

}


module.exports={createStorage}