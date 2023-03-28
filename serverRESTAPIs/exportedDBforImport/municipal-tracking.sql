-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Mar 28, 2023 at 06:30 AM
-- Server version: 8.0.31
-- PHP Version: 8.0.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `municipal-tracking`
--

-- --------------------------------------------------------

--
-- Table structure for table `faulttable`
--

DROP TABLE IF EXISTS `faulttable`;
CREATE TABLE IF NOT EXISTS `faulttable` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uid` int NOT NULL,
  `accountNumber` varchar(200) NOT NULL,
  `propertyAddress` varchar(200) NOT NULL,
  `electricityFaultDes` varchar(2000) DEFAULT NULL,
  `waterFaultDes` varchar(2000) DEFAULT NULL,
  `dateReported` datetime NOT NULL,
  `depAllocation` varchar(200) DEFAULT NULL,
  `faultResolved` tinyint(1) NOT NULL DEFAULT '0',
  `faultDes` varchar(200) DEFAULT NULL,
  `faultIMG` blob,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf32;

-- --------------------------------------------------------

--
-- Table structure for table `imagetable`
--

DROP TABLE IF EXISTS `imagetable`;
CREATE TABLE IF NOT EXISTS `imagetable` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uid` int NOT NULL,
  `propertyAddress` int NOT NULL,
  `electricMeterIMG` blob,
  `waterMeterIMG` blob,
  `uploadTime` datetime NOT NULL,
  `capturedFrom` varchar(2000) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf32;

-- --------------------------------------------------------

--
-- Table structure for table `pdftable`
--

DROP TABLE IF EXISTS `pdftable`;
CREATE TABLE IF NOT EXISTS `pdftable` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pdffile` blob NOT NULL,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf32;

-- --------------------------------------------------------

--
-- Table structure for table `propertytable`
--

DROP TABLE IF EXISTS `propertytable`;
CREATE TABLE IF NOT EXISTS `propertytable` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accountNumber` varchar(200) NOT NULL,
  `address` varchar(200) NOT NULL,
  `cellNumber` varchar(200) NOT NULL,
  `ebill` varchar(2000) NOT NULL,
  `electricityMeterNumber` varchar(200) NOT NULL,
  `electricityMeterReading` varchar(200) NOT NULL,
  `waterMeterNumber` varchar(200) NOT NULL,
  `waterMeterReading` varchar(200) NOT NULL,
  `firstName` varchar(200) NOT NULL,
  `LastName` varchar(200) NOT NULL,
  `idNumber` varchar(200) NOT NULL,
  `uid` int NOT NULL,
  `monthUpdated` datetime NOT NULL,
  `year` year NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf32;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `uid` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(200) NOT NULL,
  `lastName` varchar(200) NOT NULL,
  `cellNumber` varchar(200) NOT NULL,
  `email` varchar(200) NOT NULL,
  `password` varchar(200) NOT NULL,
  `userName` varchar(200) NOT NULL,
  `adminRoll` varchar(200) DEFAULT NULL,
  `official` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf32;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`uid`, `firstName`, `lastName`, `cellNumber`, `email`, `password`, `userName`, `adminRoll`, `official`) VALUES
(1, 'Jhon', 'Doe', '+27761234709', 'jhon@email.com', 'e10adc3949ba59abbe56e057f20f883e', 'Jhon', 'Admin', 1);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
