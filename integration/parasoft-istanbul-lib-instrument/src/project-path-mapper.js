'use strict';

const fs = require('fs');
const path = require('path');
const { name } = require('../package.json');
const debug = require('debug')(name);

const knownRoots = [];

function map(filePath) {
    const workingDir = path.resolve(process.cwd());
    if (typeof filePath !== 'string' || filePath === '') {
        return undefined;
    }
    const resolvedDir = path.dirname(path.resolve(workingDir, filePath));
    const cached = findCachedRoot(resolvedDir);
    if (cached) {
        return cached;
    }
    return findPackageJsonRoot(resolvedDir, workingDir);
}

function findCachedRoot(directory) {
    let match = null;
    for (const entry of knownRoots) {
        if (isWithinDirectory(directory, entry.root)) {
            if (!match || entry.root.length > match.root.length) {
                match = entry;
            }
        }
    }
    return match ? match.result : null;
}

function findPackageJsonRoot(startingDir, workingDir) {
    let currentDir = path.resolve(startingDir);
    let result = null;

    while (isWithinDirectory(currentDir, workingDir)) {
        const packageJsonPath = path.join(currentDir, 'package.json');
        if (fs.existsSync(packageJsonPath)) {
            try {
                const packageJson = JSON.parse(
                    fs.readFileSync(packageJsonPath, 'utf8')
                );
                result = {
                    name:
                        typeof packageJson.name === 'string'
                            ? packageJson.name
                            : 'unknown',
                    root: toPortablePath(currentDir)
                };
            } catch (err) {
                debug(`[WARNING] Failed to read name property in ${packageJsonPath}: ${err.message}`);
                result = {
                    name: 'unknown',
                    root: toPortablePath(currentDir)
                };
            }
            break;
        }

        if (currentDir === workingDir) {
            break;
        }
        const parentDir = path.dirname(currentDir);
        if (parentDir === currentDir) {
            break;
        }
        currentDir = parentDir;
    }

    if (!result) {
        result = createFallbackMapping(workingDir);
        currentDir = workingDir;
    }
    knownRoots.push({ root: currentDir, result });
    return result;
}

function isWithinDirectory(directory, rootDirectory) {
    const relativePath = path.relative(rootDirectory, directory);
    return (
        relativePath === '' ||
        (relativePath !== '..' &&
            !relativePath.startsWith(`..${path.sep}`) &&
            !path.isAbsolute(relativePath))
    );
}

function createFallbackMapping(workingDir) {
    return {
        name: path.basename(workingDir),
        root: toPortablePath(workingDir)
    };
}

function toPortablePath(directory) {
    return directory.replace(/\\/g, '/');
}

module.exports = { map };
