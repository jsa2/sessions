//https://www.tech-hour.com/nodejs-udp-server
const datagram = require("dgram");
const socket = datagram.createSocket("udp4");
//listen incomming messages


console.log(`to contact server type following \r\n echo "New Message from client" | nc -u 127.0.0.1 6000 `)

socket.on("message",(msg,receInfo)=>{
    //display msg and sender information ip:port
    console.log(`I Have Already Received: ${msg} from ${receInfo.address}:${receInfo.port}`);
})



socket.bind(6000);