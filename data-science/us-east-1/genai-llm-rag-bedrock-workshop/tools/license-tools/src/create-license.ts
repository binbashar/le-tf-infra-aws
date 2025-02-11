import * as fs from 'fs';
import * as path from 'path';
import { readLicenseConfig, LicenseType, isValidLicenseType } from './utils';
import { aslLicenseText, mitLicenseText, apache2LicenseText } from './licenses';

interface CreateLicenseOptions {
  /** Root directory where LICENSE file will be created */
  rootDir?: string;
  /** Type of license to use */
  licenseType?: LicenseType;
  /** Organization name to use in license */
  organization?: string;
  /** Year for copyright notice */
  year?: string;
}

const LICENSE_TEXTS: Record<LicenseType, string> = {
  ASL: aslLicenseText,
  MIT: mitLicenseText,
  APACHE2: apache2LicenseText
} as const;

/**
 * Prepares the license text by replacing placeholders
 */
function prepareLicenseText(licenseText: string, options: CreateLicenseOptions): string {
  const year = options.year || new Date().getFullYear().toString();
  let text = licenseText
    .replace(/\[year]/g, year)
    .replace(/\[yyyy]/g, year);

  if (options.organization) {
    text = text
      .replace(/\[fullname]/g, options.organization)
      .replace(/\[name of copyright owner]/g, options.organization)
      .replace(/\[Your Organization]/g, options.organization);
  }

  return text;
}

/**
 * Creates or updates the NOTICE file for Apache 2.0 license
 */
function createNoticeFile(projectDir: string, noticeText: string): void {
  const noticePath = path.join(projectDir, 'NOTICE');
  fs.writeFileSync(noticePath, noticeText, 'utf8');
  console.log('----------------------');
  console.log(`Created/Updated NOTICE file at ${projectDir}`);
  console.log('----------------------');
}

/**
 * Removes the NOTICE file if it exists
 */
function removeNoticeFile(rootDir: string): void {
  const noticePath = path.join(rootDir, 'NOTICE');
  if (fs.existsSync(noticePath)) {
    fs.unlinkSync(noticePath);
    console.log('----------------------');
    console.log(`Removed NOTICE file at ${noticePath}`);
    console.log('----------------------');
  }
}

/**
 * Creates a LICENSE file in the specified directory
 * @param options Configuration options for license creation
 * @param configPath Optional path to configuration file
 */
export function createLicenseFile(
  options: CreateLicenseOptions = {},
  configPath?: string
): void {
  // Read config file first
  const { config: fileConfig, configDir } = readLicenseConfig(configPath);

  // Merge file config with provided options (options take precedence)
  const mergedOptions = {
    ...fileConfig,
    ...options,
    rootDir: options.rootDir || fileConfig.rootDir || process.cwd(),
    year: options.year || fileConfig.year || new Date().getFullYear().toString()
  };

  // Resolve rootDir relative to the config file location or current working directory
  const rootDir = mergedOptions.rootDir
    ? path.resolve(configDir || process.cwd(), mergedOptions.rootDir)
    : process.cwd();

  const {
    licenseType = 'ASL' as LicenseType,
    organization,
    year
  } = mergedOptions;

  if (!isValidLicenseType(licenseType)) {
    throw new Error(`Invalid license type: ${licenseType}`);
  }

  const licenseText = LICENSE_TEXTS[licenseType];
  if (!licenseText) {
    throw new Error(`Unknown license type: ${licenseType}`);
  }

  const preparedText = prepareLicenseText(licenseText, { organization, year });
  const licensePath = path.join(rootDir, 'LICENSE');


  console.log('Config directory:', configDir);
  console.log('Resolved root directory:', rootDir);

  fs.writeFileSync(licensePath, preparedText, 'utf8');
  console.log('----------------------');
  console.log(`Created LICENSE file at ${licensePath}`);
  console.log('----------------------');

  // Create NOTICE file for APACHE2 License
  if (licenseType === 'APACHE2') {
    let noticeTemplate: string;
    if (fileConfig.additionalNotice){
      noticeTemplate = `This product includes software developed by
${organization}, all rights reserved.
${fileConfig.additionalNotice ? `\n${fileConfig.additionalNotice}` : ''}`;
    }
    else {
      noticeTemplate = `This product includes software developed by
${organization}, all rights reserved.`;
    }

    createNoticeFile(rootDir, noticeTemplate)

  } else {
    // Remove NOTICE file if it exists and we're not using Apache 2.0
    removeNoticeFile(rootDir);
  }

}

/**
 * Parse command line arguments
 */
function parseCommandLineArgs(): { options: CreateLicenseOptions, configPath?: string } {
  const args = process.argv.slice(2);
  //console.log('Command line arguments:', args);
  const options: CreateLicenseOptions = {};
  let configPath: string | undefined;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    switch (arg) {
      case '--license':
        options.licenseType = args[++i] as LicenseType;
        break;
      case '--org':
        options.organization = args[++i];
        break;
      case '--year':
        options.year = args[++i];
        break;
      case '--root':
        options.rootDir = args[++i];
        break;
      case '--config':
        configPath = args[++i];
        break;
    }
  }

  return { options, configPath };
}

// CLI handling
if (require.main === module) {
  const { options, configPath } = parseCommandLineArgs();
  createLicenseFile(options, configPath);
}