const fs = require("node:fs");

const json = JSON.parse(fs.readFileSync("golden_liquid.json"));

json.test_groups.forEach((group) => {
  const name = group.name.replace("liquid.golden.", "");
  console.log(`${name}.nim`);
  if (!fs.existsSync(`${name}.nim`)) {
    fs.writeFileSync(`${name}.nim`, JSON.stringify(group.tests, null, 2));
  }
});
