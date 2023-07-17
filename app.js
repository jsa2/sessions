var path = require('path')
const { init, express } = require('./src/preinit')
const app = init()
const crypto = require('crypto');
const zlib = require('zlib');
const appId = "396b69e9-808f-45d0-9d68-67e0f858c621"
/* const appId = "a206031a-08b3-4570-b7bf-1dbf4f80348a" */


app.get('/wsfed', async (req, res) => {
    
    const wsfedURL = `https://login.microsoftonline.com/common/wsfed?wtrealm=${appId}&wctx=WSfedState&wa=wsignin1.0`
    return res.redirect(wsfedURL)

});

app.get('/saml', async (req, res) => {
    const id = `id${crypto.randomBytes(16).toString('hex')}`;
    const issueInstant = new Date().toISOString();
    let authnRequest = `<samlp:AuthnRequest xmlns="urn:oasis:names:tc:SAML:2.0:metadata" ID="${id}" 
    Version="2.0" IssueInstant="${issueInstant}"
     xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol">
     <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">${appId}</Issuer></samlp:AuthnRequest>`;

    const deflatedRequest = await zlib.deflateRawSync(authnRequest);
    const base64Request = deflatedRequest.toString('base64');
    const ssoUrl = `https://login.microsoftonline.com/common/saml2?SAMLRequest=${encodeURIComponent(base64Request)}`;
    return res.redirect(ssoUrl);
});

app.use('/any', (req, res) => {

    /* console.log(req.body?.SAMLResponse) */
    res.setHeader('content-type','application/xml')

    if (req?.body?.wresult) {
        return res.send(req?.body?.wresult)
    }
    let sd = Buffer.from(req.body?.SAMLResponse,'base64url').toString()
    console.log(sd)


    
    return res.send(sd)
})






