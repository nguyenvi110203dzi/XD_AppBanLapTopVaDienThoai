const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Cauhinh_bonho = sequelize.define('cauhinh_bonho', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    hedieuhanh: {
        type: DataTypes.STRING,
        allowNull: false
    },
    chip_CPU: {
        type: DataTypes.TEXT
    },
    tocdo_CPU: {
        type: DataTypes.TEXT
    },
    chip_dohoa: {
        type: DataTypes.TEXT
    },
    ram: {
        type: DataTypes.TEXT
    },
    dungluong_luutru: {
        type: DataTypes.TEXT
    },
    dungluong_khadung: {
        type: DataTypes.TEXT
    },
    thenho: {
        type: DataTypes.TEXT
    },
    danhba: {
        type: DataTypes.TEXT
    },
    id_product: {
        type: DataTypes.INTEGER,
        allowNull: false,
    }
}, {
    tableName: 'cauhinh_bonho',
    timestamps: false
});

module.exports = Cauhinh_bonho;