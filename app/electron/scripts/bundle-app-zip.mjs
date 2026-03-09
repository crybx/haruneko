import path from 'node:path';
import fs from 'node:fs/promises';
import { run } from '../../tools.mjs';

const pkgFile = 'package.json';
const pkgConfig = JSON.parse(await fs.readFile(pkgFile));

/**
 * Bundle Portable Binary for Windows
 * See: https://www.electronjs.org/docs/latest/tutorial/application-distribution#manual-packaging
 */
export async function bundle(blinkApplicationSourceDirectory, blinkApplicationResourcesDirectory, blinkDeploymentTemporaryDirectory, blinkDeploymentOutputDirectory) {
    await bundleApp(blinkApplicationSourceDirectory, blinkDeploymentTemporaryDirectory);
    await makePortable(blinkDeploymentTemporaryDirectory);
    await updateBinary(blinkApplicationResourcesDirectory, blinkDeploymentTemporaryDirectory);
    await createLocalLauncher(blinkDeploymentTemporaryDirectory);
    // TODO: include ffmpeg
    // TODO: include imagemagick
    // TODO: include kindlegen
    await createZipArchive(blinkDeploymentTemporaryDirectory, blinkDeploymentOutputDirectory);
}

async function bundleApp(blinkApplicationSourceDirectory, blinkDeploymentTemporaryDirectory) {
    const target = path.join(blinkDeploymentTemporaryDirectory, 'resources', 'app');
    await fs.cp(blinkApplicationSourceDirectory, target, { recursive: true });
}

async function makePortable(blinkDeploymentTemporaryDirectory) {
    const userdata = path.join(blinkDeploymentTemporaryDirectory, 'userdata');
    await fs.mkdir(userdata, { recursive: true });
    const pkgfile = path.join(blinkDeploymentTemporaryDirectory, 'resources', 'app', 'package.json');
    const pkg = await JSON.parse(await fs.readFile(pkgfile));
    pkg['user-data-dir'] = 'userdata';
    await fs.writeFile(pkgfile, JSON.stringify(pkg, null, 4));
}

async function updateBinary(blinkApplicationResourcesDirectory, blinkDeploymentTemporaryDirectory) {
    const binary = path.join(blinkDeploymentTemporaryDirectory, 'electron.exe');
    const icon = path.join(blinkApplicationResourcesDirectory, process.platform, 'app.ico');
    const rcedit = path.join(blinkApplicationResourcesDirectory, process.platform, 'rcedit64.exe');
    const command = [
        rcedit,
        `"${binary}"`,
        `--set-version-string "ProductName" "${pkgConfig.title}"`,
        `--set-version-string "CompanyName" ""`,
        `--set-version-string "LegalCopyright" "${new Date().getFullYear()}"`,
        `--set-version-string "FileDescription" "${pkgConfig.description}"`,
        `--set-version-string "InternalName" ""`,
        `--set-version-string "OriginalFilename" "${pkgConfig.name}.exe"`,
        //`--set-file-version "0.54.0"`,
        //`--set-product-version "0.54.0"`,
        `--set-icon "${icon}"`
    ].join(' ');
    await run(command);
    await fs.rename(binary, binary.replace(/electron\.exe$/i, `${pkgConfig.name}.exe`));
}

async function createLocalLauncher(blinkDeploymentTemporaryDirectory) {
    const batFile = path.join(blinkDeploymentTemporaryDirectory, `${pkgConfig.name}-local.bat`);
    await fs.writeFile(batFile, `@echo off\r\nstart "" "%~dp0${pkgConfig.name}.exe" --local\r\n`);
}

async function createZipArchive(blinkDeploymentTemporaryDirectory, blinkDeploymentOutputDirectory) {
    const artifact = path.join(blinkDeploymentOutputDirectory, path.basename(blinkDeploymentTemporaryDirectory).replace(/^electron/i, pkgConfig.name) + '.zip');
    try {
        await fs.unlink(artifact);
    } catch(error) {/**/}
    const command = `powershell "Compress-Archive '${blinkDeploymentTemporaryDirectory}' '${artifact}'"`;
    await run(command);
}