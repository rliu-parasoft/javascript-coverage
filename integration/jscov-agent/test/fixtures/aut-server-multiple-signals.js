console.log('AUT_SERVER_ENTERED');

setTimeout(() => {
    process.emit('SIGINT');
    process.emit('SIGTERM');
}, 25);
setInterval(() => undefined, 1_000);
