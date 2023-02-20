-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 20, 2023 at 12:42 PM
-- Server version: 10.4.27-MariaDB
-- PHP Version: 8.2.0

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

CREATE TABLE `faulttable` (
  `id` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `accountNumber` varchar(200) NOT NULL,
  `propertyAddress` varchar(200) NOT NULL,
  `electricityFaultDes` varchar(2000) DEFAULT NULL,
  `waterFaultDes` varchar(2000) DEFAULT NULL,
  `dateReported` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `imagetable`
--

CREATE TABLE `imagetable` (
  `id` int(11) NOT NULL,
  `uid` int(11) NOT NULL,
  `propertyAddress` varchar(200) NOT NULL,
  `electricMeterIMG` blob DEFAULT NULL,
  `waterMeterIMG` blob DEFAULT NULL,
  `uploadTime` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pdftable`
--

CREATE TABLE `pdftable` (
  `id` int(11) NOT NULL,
  `pdffile` blob NOT NULL,
  `name` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `propertytable`
--

CREATE TABLE `propertytable` (
  `id` int(11) NOT NULL,
  `accountNumber` varchar(200) NOT NULL,
  `address` varchar(200) NOT NULL,
  `cellNumber` varchar(200) NOT NULL,
  `ebill` varchar(200) NOT NULL,
  `electricityMeterNumber` varchar(200) NOT NULL,
  `electricityMeterReading` varchar(200) NOT NULL,
  `waterMeterNumber` varchar(200) NOT NULL,
  `waterMeterReading` varchar(200) NOT NULL,
  `firstName` varchar(200) NOT NULL,
  `lastName` varchar(200) NOT NULL,
  `idNumber` varchar(200) NOT NULL,
  `uid` int(11) NOT NULL,
  `monthUpdated` datetime NOT NULL,
  `year` year(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `uid` int(11) NOT NULL,
  `firstName` varchar(200) NOT NULL,
  `lastName` varchar(200) NOT NULL,
  `cellNumber` varchar(200) NOT NULL,
  `email` varchar(200) NOT NULL,
  `password` varchar(200) NOT NULL,
  `userName` varchar(200) NOT NULL,
  `adminRoll` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `faulttable`
--
ALTER TABLE `faulttable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `imagetable`
--
ALTER TABLE `imagetable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pdftable`
--
ALTER TABLE `pdftable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `propertytable`
--
ALTER TABLE `propertytable`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`uid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `faulttable`
--
ALTER TABLE `faulttable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `imagetable`
--
ALTER TABLE `imagetable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pdftable`
--
ALTER TABLE `pdftable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `propertytable`
--
ALTER TABLE `propertytable`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
