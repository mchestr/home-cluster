module.exports = {
  hostRules: [
    {
      matchHost: "https://gitlab.com",
      token: process.env.RENOVATE_GITLAB_TOKEN,
      hostType: "gitlab",
    },
  ],
};
