const { assert } = require('chai');
const {
  BN,
  constants,
  expectEvent,
  expectRevert,
  ether,
  time,
} = require('@openzeppelin/test-helpers');

const TestClnyToken = artifacts.require('TestClnyToken');
const TestLPToken = artifacts.require('TestLPToken');
const ColonyChef = artifacts.require('ColonyChef');

contract('Restrictions', (accounts) => {
  const [ownerOfAll, user1, user2] = accounts;

  let clny;
  let lp;
  let chef;

  before(async () => {
    clny = await TestClnyToken.deployed();
    lp = await TestLPToken.deployed();
    chef = await ColonyChef.deployed();
  });

  it('Approve, transfer', async () => {
    await clny.approve(chef.address, constants.MAX_UINT256, { from: ownerOfAll });
    await lp.transfer(user1, ether('100'), { from: ownerOfAll });
    await lp.transfer(user2, ether('100'), { from: ownerOfAll });
    await lp.approve(chef.address, constants.MAX_UINT256, { from: user1 });
    await lp.approve(chef.address, constants.MAX_UINT256, { from: user2 });
  });

  it('User1 stakes', async () => {
    await chef.deposit(ether('10'), { from: user1 });
  });

  it('changeClnyPerSecond - ownable', async () => {
    time.increase(60 * 60 * 24);
    time.increase(60 * 60 * 24);
    await chef.changeRewardPerSecond(ether('3'), { from: ownerOfAll });
    await expectRevert(chef.changeRewardPerSecond(ether('5'), { from: user1 }), 'caller is not the owner');
  });
});
