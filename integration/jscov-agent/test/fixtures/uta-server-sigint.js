const http = require('node:http');

console.log('UTA_SERVER_ENTERED');

function emitSigintAfterAgentStarts() {
    const request = http.get({
        hostname: '127.0.0.1',
        port: 8050,
        path: '/status',
        agent: false
    }, (response) => {
        response.resume();
        response.once('end', () => process.emit('SIGINT'));
    });
    request.once('error', () => setTimeout(emitSigintAfterAgentStarts, 25));
}

emitSigintAfterAgentStarts();
setInterval(() => undefined, 1_000);
