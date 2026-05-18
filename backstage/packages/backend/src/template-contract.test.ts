import fs from 'node:fs';
import path from 'node:path';

const repoRoot = path.resolve(__dirname, '../../../../');
const repoSlug = 'Itamar-Ratson/backstage-k8s-full';
const repoUrl = `https://github.com/${repoSlug}`;
const chartTemplatePath = 'templates/helm-chart/template.yaml';
const decommissionTemplatePath = 'templates/helm-chart-decommission/template.yaml';
const chartCatalogPath = 'templates/helm-chart/skeleton/catalog-info.yaml.njk';
const readmePath = 'README.md';

function readRepoFile(relativePath: string) {
  return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
}

describe('helm chart template contract', () => {
  it('registers the template and publishes the expected scaffold', () => {
    const fileExpectations = [
      {
        path: 'catalog-info.yaml',
        snippets: [
          'kind: Location',
          `target: ${repoUrl}/blob/main/templates/helm-chart/template.yaml`,
        ],
      },
      {
        path: chartTemplatePath,
        snippets: [
          'kind: Template',
          'title: New Helm Chart',
          'branchName: scaffold/helm-chart/${{ parameters.name }}',
          'draft: false',
          'targetPath: charts/${{ parameters.name }}',
        ],
      },
      {
        path: chartCatalogPath,
        snippets: [
          'lifecycle: experimental',
          'backstage.io/kubernetes-id: ${{ values.name }}',
          `github.com/project-slug: ${repoSlug}`,
          `backstage.io/source-location: url:${repoUrl}/tree/main/charts/` +
            '${{ values.name }}/',
        ],
      },
    ] as const;

    for (const { path: relativePath, snippets } of fileExpectations) {
      const contents = readRepoFile(relativePath);
      for (const snippet of snippets) {
        expect(contents).toContain(snippet);
      }
    }

    const readme = readRepoFile(readmePath);
    const templateSection = '**Add the Helm chart scaffolder template**';
    const techDocsSection = '**Set up TechDocs**';
    expect(readme).toContain(templateSection);
    expect(readme.indexOf(templateSection)).toBeLessThan(readme.indexOf(techDocsSection));
  });
});

describe('helm chart decommission template contract', () => {
  it('registers the template and documents the decommission flow', () => {
    const fileExpectations = [
      {
        path: 'catalog-info.yaml',
        snippets: [
          'kind: Location',
          `target: ${repoUrl}/blob/main/templates/helm-chart-decommission/template.yaml`,
        ],
      },
      {
        path: decommissionTemplatePath,
        snippets: [
          'kind: Template',
          'branchName: decommission/helm-chart/',
          'filesToDelete:',
          'targetBranchName: main',
          'action: util:assert',
          'action: catalog:fetch',
          'action: fetch:plain',
          'action: fs:readdir',
          'draft: false',
        ],
      },
      {
        path: chartCatalogPath,
        snippets: ['backstage.io/managed-by-template: helm-chart'],
      },
    ] as const;

    for (const { path: relativePath, snippets } of fileExpectations) {
      const contents = readRepoFile(relativePath);
      for (const snippet of snippets) {
        expect(contents).toContain(snippet);
      }
    }

    const readme = readRepoFile(readmePath);
    const templateSection = '**Add the Helm chart scaffolder template**';
    const decommissionSection = '**Decommission a scaffolded Helm chart**';
    const techDocsSection = '**Set up TechDocs**';
    expect(readme).toContain(decommissionSection);
    expect(readme.indexOf(templateSection)).toBeLessThan(
      readme.indexOf(decommissionSection),
    );
    expect(readme.indexOf(decommissionSection)).toBeLessThan(
      readme.indexOf(techDocsSection),
    );
  });
});
