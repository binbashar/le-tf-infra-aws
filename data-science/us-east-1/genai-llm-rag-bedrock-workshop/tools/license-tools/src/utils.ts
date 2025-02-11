import * as fs from 'fs';
import * as path from 'path';

// Supported License Types
export type LicenseType = 'ASL' | 'MIT' | 'APACHE2';

/*
 * Checks if the license type given is valid or not
 */
export function isValidLicenseType(type: string): type is LicenseType {
  return ['ASL', 'MIT', 'APACHE2'].includes(type);
}

/**
 * Interface for the license configuration file
 */
export interface LicenseConfigFile {
  licenseType: string;
  organization: string;
  additionalNotice?: string;
  rootDir?: string;
  year?: string;
}

/**
 * Reads and parses the license configuration file
 * @param configPath Optional path to the config file
 * @returns Configuration object
 */
export function readLicenseConfig(configPath?: string): { config: Partial<LicenseConfigFile>, configDir?: string } {
  const defaultConfigPaths = [
    // Look for config file in current directory
    path.join(__dirname, 'license-config.json'),
    // Look for config file in tools/license-tools directory
    path.join(__dirname, '..', 'license-config.json'),
    // Look for config file in parent directory (monorepo root)
    path.join(process.cwd(), '..', '..', 'license-config.json')
  ];

  // console.log('Default config paths:', defaultConfigPaths);
  // console.log('Current working directory:', process.cwd());
  // console.log('__dirname:', __dirname);

  const configFile = configPath || defaultConfigPaths.find(p => {
    const exists = fs.existsSync(p);
    console.log(`Checking path ${p}: ${exists ? 'exists' : 'not found'}`);
    return exists;
  });


  if (configFile && fs.existsSync(configFile)) {
    try {
      const config = JSON.parse(fs.readFileSync(configFile, 'utf8')) as LicenseConfigFile;
      console.log(`Using license configuration from ${configFile}`);
      return {
        config,
        configDir: path.dirname(configFile)
      };

    } catch (error) {
      console.warn(`Error reading license config file: ${error}`);
    }
  }

  console.log("No valid config file found");
  return { config: {} };
}