import fs from 'node:fs';
import path from 'node:path';

const repoRoot = path.resolve(__dirname, '../../../../');

function readRepoFile(relativePath: string) {
  return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8');
}

describe('helm chart template contract', () => {
  it('registers the template and publishes the expected scaffold', () => {
    const rootCatalog = readRepoFile('catalog-info.yaml');
    expect(rootCatalog).toContain('kind: Location');
    expect(rootCatalog).toContain('target: https://github.com/Itamar-Ratson/backstage-k8s-full/blob/main/templates/helm-chart/template.yaml');

    const template = readRepoFile('templates/helm-chart/template.yaml');
    expect(template).toContain('kind: Template');
    expect(template).toContain('title: New Helm Chart');
    expect(template).toContain('branchName: scaffold/helm-chart/${{ parameters.name }}');
    expect(template).toContain('draft: false');
    expect(template).toContain('targetPath: charts/${{ parameters.name }}');

    const catalogInfo = readRepoFile('templates/helm-chart/skeleton/catalog-info.yaml');
    expect(catalogInfo).toContain('lifecycle: experimental');
    expect(catalogInfo).toContain('backstage.io/kubernetes-id: ${{ values.name }}');
    expect(catalogInfo).toContain('github.com/project-slug: Itamar-Ratson/backstage-k8s-full');
    expect(catalogInfo).toContain('backstage.io/source-location: url:https://github.com/Itamar-Ratson/backstage-k8s-full/tree/main/charts/${{ values.name }}/');

    const readme = readRepoFile('README.md');
    expect(readme).toContain('**Add the Helm chart scaffolder template**');
    expect(readme.indexOf('**Add the Helm chart scaffolder template**')).toBeLessThan(
      readme.indexOf('**Set up TechDocs**'),
    );
  });
});
