module.exports = {
  hostRules: [
    {
      hostType: "docker",
      matchHost: "ghcr.io/mchestr/decision-decider",
      token: process.env.RENOVATE_TOKEN,
    },
  ],
};
