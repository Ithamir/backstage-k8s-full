import fs from 'node:fs';
import path from 'node:path';

const repoRoot = path.resolve(__dirname, '../../../../');
const repoSlug = 'Itamar-Ratson/backstage-k8s-full';
const repoUrl = `https://github.com/${repoSlug}`;
const chartTemplatePath = 'templates/helm-chart/template.yaml';
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
