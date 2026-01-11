const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Camera_manhinh = sequelize.define('camera_manhinh', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    dophangiai_camsau: {
        type: DataTypes.STRING,
        allowNull: false
    },
    congnghe_camsau: {
        type: DataTypes.TEXT
    },
    denflash_camsau: {
        type: DataTypes.TINYINT(1)
    },
    tinhnang_camsau: {
        type: DataTypes.TEXT
    },
    dophangiai_camtruoc: {
        type: DataTypes.TEXT
    },
    tinhnang_camtruoc: {
        type: DataTypes.TEXT
    },
    congnghe_manhinh: {
        type: DataTypes.TEXT
    },
    dophangiai_manhinh: {
        type: DataTypes.TEXT
    },
    rong_manhinh: {
        type: DataTypes.TEXT
    },
    dosang_manhinh: {
        type: DataTypes.TEXT
    },
    matkinh_manhinh: {
        type: DataTypes.TEXT
    },
    id_product: {
        type: DataTypes.INTEGER,
        allowNull: false,
    }
},{
    tableName: 'camera_manhinh',
    timestamps: false
});

module.exports = Camera_manhinh;