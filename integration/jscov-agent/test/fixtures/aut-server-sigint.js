console.log('AUT_SERVER_ENTERED');

setTimeout(() => process.emit('SIGINT'), 25);
setInterval(() => undefined, 1_000);
