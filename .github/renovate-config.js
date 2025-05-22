module.exports = {
  hostRules: [
    {
      matchHost: "https://gitlab.com",
      username: "mchestr",
      password: process.env.RENOVATE_GITLAB_TOKEN,
      hostType: "gitlab",
    },
  ],
};
