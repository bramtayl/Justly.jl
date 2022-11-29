#pragma once

#include <QObject>
#include <QTest>

#include "Editor.h"

class TestEverything: public QObject
{
    Q_OBJECT
private slots:
 static void test_everything();
};
