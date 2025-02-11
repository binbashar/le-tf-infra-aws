import * as fs from 'fs';
import * as path from 'path';
import { readLicenseConfig, LicenseType, isValidLicenseType } from './utils';

/**
 * Interface defining the structure of a license configuration
 */
interface LicenseConfig {
  /** Name of the license */
  name: string;
  /** The full text of the license header */
  headerText: string;
  /** Optional additional notice text */
  noticeText?: string;
  /** Identifier patterns to detect this license in existing files */
  identifierPatterns: string[];
}

/**
 * Available license configurations
 */
const LICENSES: Record<string, LicenseConfig> = {
  ASL: {
    name: 'Amazon Software License',
    headerText: `Copyright Amazon.com and its affiliates; all rights reserved.
SPDX-License-Identifier: LicenseRef-.amazon.com.-AmznSL-1.0
Licensed under the Amazon Software License  https://aws.amazon.com/asl/`,
    identifierPatterns: [
      'Amazon Software License',
      'LicenseRef-.amazon.com.-AmznSL-1.0'
    ]
  },
  MIT: {
    name: 'MIT License',
    headerText: `Copyright (c) ${new Date().getFullYear()} [Your Organization]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.`,
    identifierPatterns: [
      'MIT License',
      'Permission is hereby granted, free of charge'
    ]
  },
  APACHE2: {
    name: 'Apache License, Version 2.0',
    headerText: `Copyright [yyyy] [name of copyright owner]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.`,
    noticeText: `This product includes software developed by
[Your Organization]
[Optional additional notices]`,
    identifierPatterns: [
      'Apache License, Version 2.0',
      'Licensed under the Apache License'
    ]
  }
} as const;

/**
 * Creates a JavaScript/TypeScript style comment block from license text
 */
function createJsLicenseComment(licenseText: string): string {
  return `/*
${licenseText.split('\n').map((line, index) => (index === 0 && line.trim().length > 0) ? `* ${line.trim()}` : `* ${line}`).join('\n')}
*/`;
}

/**
 * Creates a Python style comment block from license text
 */
function createPyLicenseComment(licenseText: string): string {
  return `# ${licenseText.split('\n').filter(line => line.trim().length > 0).join('\n# ')}`;
}


/**
 * Prepares the license text by replacing placeholders
 */
function prepareLicenseText(licenseText: string, options: LicenseHeaderOptions): string {
  const year = new Date().getFullYear().toString();
  let text = licenseText
    .replace('[yyyy]', year)
    .replace('[year]', year);

  if (options.organization) {
    text = text
      .replace('[name of copyright owner]', options.organization)
      .replace('[Your Organization]', options.organization);
  }

  return text;
}

/**
 * Finds and removes existing license header from file content
 */
function removeExistingLicenseHeader(content: string): string {
  // Remove leading whitespace and empty lines
  content = content.trimStart();

  // Check for JavaScript/TypeScript style comment block
  if (content.startsWith('/*')) {
    const endIndex = content.indexOf('*/');
    if (endIndex !== -1) {
      return content.substring(endIndex + 2).trimStart();
    }
  }

  // Check for Python style comments
  const lines = content.split('\n');
  let headerEndIndex = 0;

  // Find where the comment block ends
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('#')) {
      headerEndIndex = i + 1;
    } else if (line === '') {
      // continue
    } else {
      break;
    }
  }

  if (headerEndIndex > 0) {
    return lines.slice(headerEndIndex).join('\n').trimStart();
  }

  return content;
}

/**
 * Checks if content contains any known license headers
 */
function hasExistingLicenseHeader(content: string): boolean {
  const upperContent = content.toUpperCase();
  return Object.values(LICENSES).some(license =>
    license.identifierPatterns.some(pattern =>
      upperContent.includes(pattern.toUpperCase())
    )
  );
}

/**
 * Interface defining the required parameters for processing a file with license headers
 */
interface ProcessFileOptions {
  filePath: string;
  processContent: (content: string) => string;
}

/**
 * Interface defining the statistics collected about files modified to have license headers
 */
interface LicenseHeaderStats {
  added: number;
  updated: number;
  total: number;
}

/**
 * Generic function to process a file and add or update license header
 */
function processFile({ filePath, processContent }: ProcessFileOptions): 'added' | 'updated' {
  const fileContent = fs.readFileSync(filePath, 'utf8');

  if (hasExistingLicenseHeader(fileContent)) {
    // Remove existing license header
    const contentWithoutHeader = removeExistingLicenseHeader(fileContent);
    const updatedContent = processContent(contentWithoutHeader);
    fs.writeFileSync(filePath, updatedContent, 'utf8');
    // console.log(`Updated license header in ${filePath}`);
    return 'updated'
  } else {
    // Add new license header
    const updatedContent = processContent(fileContent);
    fs.writeFileSync(filePath, updatedContent, "utf8");
    // console.log(`Added license header to ${filePath}`);
    return 'added'
  }
}

/**
 * Processes JavaScript/TypeScript files to add license headers
 */
function processJsLikeFile(filePath: string, licenseComment: string): 'added' | 'updated' {
  return processFile({
    filePath,
    processContent: (content) => `${licenseComment}\n\n${content}`
  });
}

/**x
 * Processes Python files to add license headers
 */
function processPythonFile(filePath: string, licenseComment: string): 'added' | 'updated' {
  return processFile({
    filePath,
    processContent: (content) => {
      const lines = content.split('\n');
      const futureImports = lines.filter(line => line.startsWith('from __future__ import'));
      const remainingContent = lines.filter(line => !line.startsWith('from __future__ import'));

      return [
        ...(futureImports.length > 0 ? [...futureImports, ''] : []),
        licenseComment,
        '',
        ...remainingContent
      ].join('\n');
    }
  });
}

/**
 * Configuration options for license header generation
 */
interface LicenseHeaderOptions {
  /** Root directory of the monorepo (defaults to current working directory) */
  rootDir?: string;
  /** Type of license to use (defaults to ASL) */
  licenseType?: LicenseType;
  /** Organization name to use in license */
  organization?: string;
  /** Additional notice text for Apache 2.0 license */
  additionalNotice?: string;
}

/**
 * Main function to generate license headers for all applicable files in a monorepo
 *
 * @param options Configuration options for license header generation
 * @param configPath Optional path to configuration file
 * @throws Error if 'packages' directory is not found
 */
export function generateLicenseHeaders(
  options: LicenseHeaderOptions = {},
  configPath?: string
): void {
  // Read config file first
  const { config: fileConfig, configDir } = readLicenseConfig(configPath);

  // Merge file config with provided options (options take precedence)
  const mergedOptions = {
    ...fileConfig,
    ...options,
    rootDir: options.rootDir || fileConfig.rootDir || process.cwd()
  };

  // Resolve rootDir relative to the config file location or current working directory
  const rootDir = mergedOptions.rootDir
    ? path.resolve(configDir || process.cwd(), mergedOptions.rootDir)
    : process.cwd();

  const {
    licenseType = 'ASL',
    organization,
    additionalNotice
  } = mergedOptions;

  if (!isValidLicenseType(licenseType)) {
    throw new Error(`Invalid license type: ${licenseType}`);
  }

  // Get and prepare the license configuration
  const licenseConfig = LICENSES[licenseType];
  let licenseText = prepareLicenseText(licenseConfig.headerText, {
    organization
  });

  console.log('Config directory:', configDir);
  console.log('Resolved root directory:', rootDir);

  // Create the formatted license comments
  const jsLicenseComment = createJsLicenseComment(licenseText);
  const pyLicenseComment = createPyLicenseComment(licenseText);

  const packagesDir = path.join(rootDir, 'packages');

  if (!fs.existsSync(packagesDir)) {
    throw new Error('packages directory not found');
  }

  const projectDirs = fs.readdirSync(packagesDir)
    .map(dir => path.join(packagesDir, dir))
    .filter(dir => fs.statSync(dir).isDirectory());

  const stats: LicenseHeaderStats = {
    added: 0,
    updated: 0,
    total: 0
  };

  for (const projectDir of projectDirs) {
    const queue: string[] = [projectDir];

    while (queue.length > 0) {
      const currentPath = queue.shift()!;
      const files = fs.readdirSync(currentPath);

      for (const file of files) {
        const filePath = path.join(currentPath, file);
        const fileStats = fs.statSync(filePath);

        if (fileStats.isDirectory()) {
          if (!['node_modules', 'site-packages', 'generated'].some(exclude => filePath.includes(exclude))) {
            queue.push(filePath);
          }
        } else if (fileStats.isFile()) {
          const dirParts = filePath.split(path.sep);
          if (dirParts.includes('src') || dirParts.includes('test')) {
            const ext = path.extname(filePath).toLowerCase();
            let operation: 'added' | 'updated' | undefined;

            if (['.ts', '.tsx', '.js', '.jsx'].includes(ext)) {
              operation = processJsLikeFile(filePath, jsLicenseComment);
            } else if (ext === '.py') {
              operation = processPythonFile(filePath, pyLicenseComment);
            }

            if (operation) {
              stats[operation]++;
              stats.total++;
            }
          }
        }
      }
    }
  }

  // Print summary
  console.log('\nLicense Header Summary:');
  console.log('----------------------');
  console.log(`Added headers:   ${stats.added}`);
  console.log(`Updated headers: ${stats.updated}`);
  console.log(`Total files:     ${stats.total}`);
  console.log('----------------------');

}

/* Main Function that takes in arguments from the script call done in the root package.json file */
function parseCommandLineArgs(): { options: any, configPath?: string } {
  const args = process.argv.slice(2);
  const options: any = {};
  let configPath: string | undefined;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    switch (arg) {
      case '--license':
        options.licenseType = args[++i];
        break;
      case '--org':
        options.organization = args[++i];
        break;
      case '--config':
        configPath = args[++i];
        break;
      case '--notice':
        options.additionalNotice = args[++i];
        break;
      case '--root':
        options.rootDir = args[++i];
        break;
    }
  }

  return { options, configPath };
}

// CLI handling
if (require.main === module) {
  const { options, configPath } = parseCommandLineArgs();
  generateLicenseHeaders(options, configPath);
}

