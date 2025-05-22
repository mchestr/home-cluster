module.exports = {
  hostRules: [
    {
      hostType: "docker",
      matchHost: "gitlab.com",
      username: "mchestr",
      password: process.env.RENOVATE_GITLAB_TOKEN,
    },
  ],
};
