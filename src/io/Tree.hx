package io;

import hxassert.Assert;
import ID.AbilityID;

typedef TreeAbility = 
{
    var id:String;
    var requires:String;
}

class Tree 
{
    private var grid(default, null):Array<Array<TreeAbility>>;

    public function getID(i:Int, j:Int):AbilityID
    {
        return AbilityID.createByName(grid[i][j].id);
    }

    public function getReqDeltas(i:Int, j:Int) 
    {
        Assert.require(i < grid.length);
        Assert.require(j < grid[i].length);

        var reqStr:String = grid[i][j].requires;
        var reqs:Array<Int> = [];
        for (k in 0...reqStr.length)
            switch (reqStr.charAt(k))
            {
                case "l": reqs.push(-1);
                case "c": reqs.push(0);
                case "r": reqs.push(1);
                default:
            }
        return reqs;
    }

    public function getAbilities():Array<AbilityID>
    {
        var a = [];
        for (row in grid)
            for (ab in row)
                a.push(AbilityID.createByName(ab.id));
        return a;
    }

    public function new(grid:Array<Array<TreeAbility>>) 
    {
        this.grid = grid;
    }

}