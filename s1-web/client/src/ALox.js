require("alox");

const Opal = window.Opal;

const ALox = {
  analyze(source) {
    return Opal.ALox.$analyze(source);
  },
};

export default ALox;
