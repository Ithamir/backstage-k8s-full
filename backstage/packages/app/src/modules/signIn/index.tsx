import { SignInPage, type IdentityProviders } from '@backstage/core-components';
import { githubAuthApiRef } from '@backstage/core-plugin-api';
import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';

const signInProviders: IdentityProviders = [
  'guest',
  {
    id: 'github-auth-provider',
    title: 'GitHub',
    message: 'Sign in using GitHub',
    apiRef: githubAuthApiRef,
  },
];

export const signInModule = createFrontendModule({
  pluginId: 'app',
  extensions: [
    SignInPageBlueprint.make({
      params: {
        loader: async () => props =>
          <SignInPage {...props} providers={signInProviders} />,
      },
    }),
  ],
});
