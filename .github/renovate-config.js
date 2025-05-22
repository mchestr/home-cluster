module.exports = {
  hostRules: [
    {
      hostType: "docker",
      matchHost: "ghcr.io",
      username: "mchestr",
      password: process.env.RENOVATE_TOKEN,
    },
  ],
};
