const http = require('node:http');

console.log('AUT_SERVER_ENTERED');

function emitSignalsAfterAgentStarts() {
    const request = http.get({
        hostname: '127.0.0.1',
        port: 8050,
        path: '/status',
        agent: false
    }, (response) => {
        response.resume();
        response.once('end', () => {
            process.emit('SIGINT');
            process.emit('SIGTERM');
        });
    });
    request.once('error', () => setTimeout(emitSignalsAfterAgentStarts, 25));
}

emitSignalsAfterAgentStarts();
setInterval(() => undefined, 1_000);
