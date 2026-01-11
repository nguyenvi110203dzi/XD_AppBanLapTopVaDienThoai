const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Pin_sac = sequelize.define('pin_sac', {
    id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    dungluong_pin: {
        type: DataTypes.STRING,
        allowNull: false
    },
    loai_pin: {
        type: DataTypes.TEXT
    },
    hotrosac_max: {
        type: DataTypes.TEXT
    },
    sac_theomay: {
        type: DataTypes.TEXT
    },
    congnghe_pin: {
        type: DataTypes.TEXT
    },
    id_product: {
        type: DataTypes.INTEGER,
        allowNull: false,
    }
}, {
    tableName: 'pin_sac',
    timestamps: false
});

module.exports = Pin_sac;